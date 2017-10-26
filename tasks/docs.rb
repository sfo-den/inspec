# encoding: utf-8
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'erb'
require 'ruby-progressbar'
require 'fileutils'
require_relative './shared'

WWW_DIR     = File.expand_path(File.join(__dir__, '..', 'www')).freeze
DOCS_DIR    = File.expand_path(File.join(__dir__, '..', 'docs')).freeze

class Markdown
  class << self
    def h1(msg)
      "# #{msg}\n\n"
    end

    def h2(msg)
      "## #{msg}\n\n"
    end

    def h3(msg)
      "### #{msg}\n\n"
    end

    def code(msg, syntax = nil)
      "```#{syntax}\n"\
      "#{msg}\n"\
      "```\n\n"
    end

    def li(msg)
      "* #{msg.gsub("\n", "\n    ")}\n"
    end

    def ul(msg)
      msg + "\n"
    end

    def p(msg)
      "#{msg}\n\n"
    end

    def a(name, dst = nil)
      dst ||= name
      "[#{name}](#{dst})"
    end

    def suffix
      '.md'
    end

    def meta(opts)
      o = opts.map { |k, v| "#{k}: #{v}" }.join("\n")
      "---\n#{o}\n---\n\n"
    end
  end
end

class RST
  class << self
    def h1(msg)
      "=====================================================\n"\
      "#{msg}\n"\
      "=====================================================\n\n"\
    end

    def h2(msg)
      "#{msg}\n"\
      "=====================================================\n\n"\
    end

    def h3(msg)
      "#{msg}\n"\
      "-----------------------------------------------------\n\n"\
    end

    def code(msg, syntax = nil)
      ".. code-block:: #{syntax}\n\n"\
      "   #{msg.gsub("\n", "\n   ")}\n\n"
    end

    def li(msg)
      "#{msg.gsub("\n", "\n   ")}\n\n"
    end

    def ul(msg)
      msg
    end

    def p(msg)
      "#{msg}\n\n"
    end

    def a(name, _dst = nil)
      # FIXME: needs link handling
      "`#{name}`_"
    end

    def suffix
      '.rst'
    end

    def meta(_o)
      '' # ignore for now
    end
  end
end

class ResourceDocs
  def initialize(root)
    @paths = {}  # cache of paths
    @root = root # relative root path for all docs
  end

  def render(path)
    @paths[path] ||= render_path(path)
  end

  def partial(x)
    render(x + '.md.erb')
  end

  private

  def render_path(path)
    abs = File.join(@root, path)
    raise "Can't find file to render in #{abs}" unless File.file?(abs)

    ERB.new(File.read(abs)).result(binding)
  end
end

namespace :docs do
  desc 'Create cli docs'
  task :cli do
    # formatter for the output file
    f = Markdown
    # list of subcommands we ignore; these are e.g. plugins
    skip_commands = %w{scap}

    res = f.meta(title: 'About the InSpec CLI')
    res << f.h1('InSpec CLI')
    res << f.p('Use the InSpec CLI to run tests and audits against targets '\
               'using local, SSH, WinRM, or Docker connections.')

    require 'inspec/cli'
    cmds = Inspec::InspecCLI.all_commands
    cmds.keys.sort.each do |key|
      next if skip_commands.include? key
      cmd = cmds[key]

      res << f.h2(cmd.usage.split.first)
      res << f.p(cmd.description.capitalize)

      res << f.h3('Syntax')
      res << f.p('This subcommand has the following syntax:')
      res << f.code("$ inspec #{cmd.usage}", 'bash')

      opts = cmd.options.select { |_, o| !o.hide }
      unless opts.empty?
        res << f.h3('Options') + f.p('This subcommand has additional options:')

        list = ''
        opts.keys.sort.each do |option|
          opt = cmd.options[option]
          # TODO: remove when UX of help is reworked 1.0
          usage = opt.usage.split(', ')
                     .map { |x| x.tr('[]', '') }
                     .map { |x| x.start_with?('-') ? x : '-'+x }
                     .map { |x| '``' + x + '``' }
          list << f.li("#{usage.join(', ')}  \n#{opt.description}")
        end.join
        res << f.ul(list)
      end

      # FIXME: for some reason we have extra lines in our RST; needs investigation
      res << "\n\n" if f == RST
    end

    dst = File.join(DOCS_DIR, "cli#{f.suffix}")
    File.write(dst, res)
    puts "Documentation generated in #{dst.inspect}"
  end

  desc 'Create resources docs'
  task :resources, [:clean] do
    src = DOCS_DIR
    dst = File.join(WWW_DIR, 'source', 'docs', 'reference', 'resources')
    FileUtils.mkdir_p(dst)

    docs = ResourceDocs.new(src)
    resources = Dir[File.join(src, 'resources/*.md.erb')]
                .map { |x| x.sub(/^#{src}/, '') }
                .sort
    puts "Found #{resources.length} resource docs"
    puts "Rendering docs to #{dst}/"

    progressbar = ProgressBar.create(total: resources.length, title: 'Rendering')
    resources.each do |file|
      progressbar.log('          '+file)
      dst_name = File.basename(file).sub(/\.md\.erb$/, '.html.md')
      res = docs.render(file)
      File.write(File.join(dst, dst_name), res)
      progressbar.increment
    end
    progressbar.finish

    f = Markdown
    res = f.meta(title: 'InSpec Resources Reference')
    res << f.h1('InSpec Resources Reference')
    res << f.p('The following InSpec audit resources are available:')
    list = ''
    resources.each do |file|
      name = File.basename(file).sub(/\.md\.erb$/, '')
      list << f.li(f.a(name.sub('_', '\\_'), 'resources/' + name + '.html'))
    end
    res << f.ul(list)
    dst = File.join(src, 'resources.md')
    puts "Create #{dst}"
    File.write(dst, res)
  end

  desc 'Clean all rendered docs from www/'
  task :clean do
    dst = File.join(WWW_DIR, 'source', 'docs', 'reference')
    puts "Clean up #{dst}"
    FileUtils.rm_rf(dst) if File.exist?(dst)
    FileUtils.mkdir_p(dst)
  end

  desc 'Copy fixed doc files'
  task copy: [:clean, :resources] do
    src = DOCS_DIR
    dst = File.join(WWW_DIR, 'source', 'docs', 'reference')
    files = Dir[File.join(src, '*.md')]

    progressbar = ProgressBar.create(total: files.length, title: 'Copying')
    files.each do |path|
      name = File.basename(path).sub(/\.md$/, '.html.md')
      progressbar.log('          '+File.join(dst, name))
      FileUtils.cp(path, File.join(dst, name))
      progressbar.increment
    end
    progressbar.finish
  end
end

def run_tasks_in_namespace(ns)
  Rake.application.in_namespace(ns) do |x|
    x.tasks.each do |task|
      puts "----> #{task}"
      task.invoke
    end
  end
end

desc 'Create all docs in docs/ from source code'
task :docs do
  run_tasks_in_namespace :docs
  Verify.file(File.join(WWW_DIR, 'source', 'docs', 'reference', 'README.html.md'))
  Verify.file(File.join(WWW_DIR, 'source', 'docs', 'reference', 'cli.html.md'))
  Verify.file(File.join(WWW_DIR, 'source', 'docs', 'reference', 'resources.html.md'))
end
