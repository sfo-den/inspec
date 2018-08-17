# Developing InSpec Plugins for the v2 plugin API

## Introduction

### Inspiration

The software design of the InSpec Plugin v2 API is deeply inspired by the Vagrant plugin v2 system.  While the InSpec Plugin v2 system is an independent implementation, acknowledgements are due to the Hashicorp team for such a well-thought-out design.

### Note About versions

"v2" refers to the second major version of the Plugin API.  It doesn't refer to the InSpec release number.

### Design Goals

* Load-on-demand. Improve `inspec` startup time by making plugins load heavy libraries only if they are being used.
* Independent velocity. Enable passionate community members to contribute at their own pace by shifting core development into plugin development
* Increase dogfooding. Convert internal components into plugins to reduce core complexity and allow testing in isolation

### Design Anti-goals

* Don't implement resources in plugins; use resource packs for that.

## How Plugins are Located and Loaded

### Plugins are usually gems

The normal distribution and installation method is via gems, handled by the `inspec plugin` command.

TODO: give basic overview of `inspec plugin` and link to docs

### Plugins may also be found by path

For local development or site-specific installations, you can also 'install' a plugin by path using `inspec plugin`, or edit `~/.inspec/plugins.json` directly to add a plugin.

### The plugins.json file

InSpec stores its list of known plugins in a file, `~/.inspec/plugins.json`. The purpose of this file is avoid having to do a gem path filesystem scan to locate plugins.  When you install, update, or uninstall a plugin using `inspec plugin`, InSpec updates this file.

You can tell inspec to use a different config directory using the INSPEC_CONFIG_DIR environment variable.

Top-level entries in the JSON file:

 * `plugins_config_version` - must have the value "1.0.0". Reserved for future format changes.
 * `plugins` - an Array of Hashes, each containing information about plugins that are expected to be installed

Each plugin entry may have the following keys:

 * `name` - Required.  String name of the plugin.  Internal machine name of the plugin. Must match `plugin_name` DSL call (see Plugin class below).
 * `installation_type` - Optional, default "gem".  Selects a loading mechanism, may be either "path" or "gem"
 * `installation_path` - Required if installation_type is "path".  A `require` will be attempted against this path.  It may be absolute or relative; InSpec adds both the process current working directory as well as the InSpec installation root to the load path.

TODO: keys for gem installations

Putting this all together, here is a plugins.json file from the InSpec test suite:

```json
{
  "plugins_config_version" : "1.0.0",
  "plugins": [
    {
      "name": "inspec-meaning-of-life",
      "installation_type": "path",
      "installation_path": "test/unit/mock/plugins/meaning_of_life_path_mode/inspec-meaning-of-life"
    }
  ]
}
```

## Plugin Parts

### A Typical Plugin File Layout

```
inspec-my-plugin.gemspec
lib/
  inspec-my-plugin.rb  # Entry point
  inspec-my-plugin/
    cli.rb             # An implementation file
    plugin.rb          # Plugin definition file
    heavyweight.rb     # A support file
```

Generally, except for the entry point, you may name these files anything you like; however, the above example is the typical convention.

### Gemspec and Plugin Dependencies

This is a normal Gem specification file. When you release your plugin as a gem, you can declare dependencies here, and InSpec will automatically install them along with your plugin.

If you are using a path-based install, InSpec will not manage your dependencies.

### Entry Point

The entry point is the file that will be `require`d at load time (*not* activation time; see Plugin Lifecycle, below).  You should load the bare minimum here - only the plugin definition file. Do not load any plugin dependencies in this file.

```ruby
# lib/inspec-my-plugin.rb
require_relative 'inspec-my-plugin/plugin'
```

### Plugin Definition File

The plugin definition file uses the plugin DSL to declare a small amount of metadata, followed by as many activation hooks as your plugin needs.

While you may use any valid Ruby module name, we encourage you to namespace your plugin under `InspecPlugins::YOUR_PLUGIN`.

```ruby
# lib/inspec-my-plugin/plugin.rb
module InspecPlugins
  module MyPlugin
    # Class name doesn't matter, but this is a reasonable default name
    class PluginDefinition < Inspec.plugin(2)

      # Metadata
      # Must match entry in plugins.json
      plugin_name :'inspec-my-plugin'

      # Activation hooks (CliCommand as an example)
      cli_command :'my-command' do
        require_relative 'cli'
        InspecPlugins::MyPlugin::CliCommand
      end

    end
  end
end
```

Note that the block passed to `cli_command` is not executed when the plugin definition is loaded.  It will only be executed if inspec decides it needs to activate that plugin component.

Every activation hook is expected to return a `Class` which will be used in post-activation or execution phases. The behavior, duck typing, and superclass of that Class vary depending on the plugin type; see below for details.

### Implementation Files

Inside the implementation files, you should be sure to do three things:

1. Load any heavyweight libraries your plugin needs
2. Create a class (which you will return from the activator hook)
3. Within the class, implement your functionality, as dictated by the plugin type API

```ruby
# lib/inspec-my-plugin/cli.rb

# Load enormous dependencies
require_relative 'heavyweight'

module InspecPlugin::MyPlugin
  # Class name doesn't matter, but this is a reasonable default name
  class CliCommand < Inspec.plugin(2, :cli_command) # Note two-arg form
    # Implement API or use DSL as dictated by cli_command plugin type
    # ...
  end
end
```

## Plugin Lifecycle

All queries regarding plugin state should be directed to `Inspec::Plugin::V2::Registry.instance`, a singleton object.

```ruby
registry = Inspec::Plugin::V2::Registry.instance
plugin_status = registry[:'inspec-meaning-of-life']
```

### Discovery (Known Plugins)

If a plugin is mentioned in `plugins.json` or is a plugin distributed with InSpec itself, it is *known*.  You can get its status, a `Inspec::Plugin::V2::Status` object.

Reading the plugins.json file is handled by the Loader when Loader.new is called; at that point the registry should know about plugins.

### Loading

Next, we load plugins.  Loading means that we `require` the entry point determined from the plugins.json. Your plugin definition file will thus execute.

If things go right, the Status now has a bunch of Activators, each with a block that has not yet executed.

If things go wrong, have a look at `status.load_exception`.

### Activation and Execution

Depending on the plugin type, activation may be triggered by a number of different events. For example, CliCommand plugin types are activated when their activation name is mentioned in the command line arguments.

After activation, code for that aspect of the plugin is loaded and ready to execute. Execution may be triggered by a number of different events. For example, the CliCommand plugin types are implicitly executed by Thor when `Inspec::CLI` calls `start()`.

Refer to the sections below for details about activation and execution timing.

## Implementing a CLI Command Plugin

The CliCommand plugin_type allows you to extend the InSpec command line interface by adding a namespace of new commands. InSpec is based on [Thor](http://whatisthor.com/) ([docs](https://www.rubydoc.info/github/wycats/thor/Thor)), and the plugin system exposes Thor directly.

CliCommand can do things like:

```bash
# A namespaced custom command with options
you@machine$ inspec sweeten add --kind sugar --teaspoons 2
# A namespaced custom command with short options
you@machine$ inspec sweeten add -k agave
# Mix global and namespace options
you@machine$ inspec --debug sweeten add -k aspartame
# Namespace included in help
you@machine$ inspec help
Commands:
  inspec archive PATH      # archive a profile to tar.gz (default) or zip
  inspec sweeten ...       # Add spoonfuls til the medicine goes down
# Detailed help
[cwolfe@lodi inspec-plugins]$ inspec help sweeten
Commands:
  inspec sweeten add [opts]       # Adds sweetener to your beverage
  inspec sweeten count            # Reports on teaspoons in your beverage, always bad news
```

Currently, it cannot create a direct (non-namespaced) command, such as `inspec mycommand` with no subcommands.

### Declare your plugin activators

In your `plugin.rb`, include one or more `cli_command` activation blocks.  The activation block name will be matched against the command line arguments; if the name is present, your activator will fire (in which case it should load any needed libraries) and should return your implementation class.

#### CliCommand Activator Example

```ruby

# In plugin.rb
module InspecPlugins::Sweeten
  class Plugin < Inspec.plugin(2)
    # ... other plugin stuff

    cli_command :sweeten do
      require_relative 'cli.rb'
      InspecPlugins::Sweeten::CliCommand
    end
  end
end
```

Like any activator, the block above will only be called if needed. For CliCommand plugins, the plugin system naively scans through ARGV, looking for the activation name as a whole element.  Multiple CliCommand activations may occur if several different names match, though each activation will only occur once.

```bash
you@machine $ inspec sweeten ... # Your CliCommand implementation is activated and executed
you@machine $ inspec exec ... # Your CliCommand implementation is not activated
```

Execution occurs implicitly via `Thor.start()`, which is handled by `bin/inspec`. Keep reading.

You should also be aware of one other activation event: if the CLI is invoked as `inspec help`, *all* CliCommand plugins will activate (but will not be executed). This is so that each plugin's help information can be registered with Thor.

### Implementation class for CLI Commands

In your `cli.rb`, you should begin by requesting the superclass from `Inspec.plugin`:

```ruby
module InspecPlugins::Sweeten
  class CliCommand < Inspec.plugin(2, :cli_command)
    # ...
  end
end
```

The Inspec plugin v2 system promises the following:

* The superclass will be an (indirect) subclass of Thor
* The plugin system will handle registering the subcommand with Thor for you
* The plugin system will handle setup of the subcommand help message for you

### Implementing your command

Within your `cli.rb`, you need to do two things:

* Inform Inspec of your subcommand's usage and description, so the `help` commands will work properly
* Implement your subcommands and options using the Thor DSL

See also: [Thor homepage](http://whatisthor.com/) and [Thor docs](https://www.rubydoc.info/github/wycats/thor/Thor).

#### Call subcommand_desc

Within your implementation, make a call like this:

```ruby
# Class declaration as above
subcommand_desc 'sweeten ...', 'Add spoonfuls til the medicine goes down'
```

The first argument is the usage message; it will be displayed whenever you execute `inspec help`, or when Thor tries to parse a malformed `inspec sweeten ...` command.

The second is the command groups description, and is displayed with `inspec help`.

Both arguments are free-form Strings intended for humans; the usage message should begin with your subcommand name to prevent user confusion.

If you neglect to call this DSL method, Thor will not register your command.

#### Adding Subcommands

The minimum needed for a command is a call to `desc` to set the help message, and a method definition named after the command.

```ruby
desc 'Reports on teaspoons in your beverage, always bad news'
def count
  # Someone has executed `inspec sweeten count` - do whatever that entails
  case beverage_type
  when :soda
    puts 12
  when :tea_two_lumps
    puts 2
  end
end
```

There is a great deal more you can do with Thor, especially concerning handling options. Refer to the Thor docs for more examples and details.

#### Using no_command

One common surprise seen with Thor is that every public instance method of your CliCommand implementation class is expected to be a CLI command definition. Thor will issue a warning if it encounters a public method definition without a `desc` call preceding it.  Two ways around this include:

* Make your helper methods private
* Enclose your non-command methods in a no_command block (a feature of Thor just for this circumstance)

```ruby
no_command do
  def beverage_type
    @bevvy
  end
end
```