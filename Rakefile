require 'json'

PROJECT_ROOT = File.dirname(__FILE__)
Dir.chdir(PROJECT_ROOT) # Ensure all paths expand relative to this Rakefile.

MODULE_METADATA = JSON.parse(File.read('metadata.json'))

PUPPETSERVER_SUBMODULE = File.join('checkouts', 'puppetserver')
# FIXME: Figure out a way to actually find the Jarfile for the currently
# checked out server version. However, this might require invoking lein
# every time rake is invoked --- which is expensive.
PUPPETSERVER_JAR = File.join(PUPPETSERVER_SUBMODULE, 'target')

FACTS_UPLOAD_JAR = File.join('target', 'facts-upload.jar')
FACTS_UPLOAD_JAR_SRCS = Rake::FileList['src/**/*.clj', 'src/**/*.rb']

FACTS_UPLOAD_MODULE = "pkg/#{MODULE_METADATA['name']}-#{MODULE_METADATA['version']}.tar.gz"
FACTS_UPLOAD_MODULE_SRCS = Rake::FileList['manifests/**/*.pp', 'files/facts-upload.jar']

namespace :puppetserver do
  desc "Build Puppet Server's JAR and install it to the local mvn repo"
  task :install => PUPPETSERVER_SUBMODULE do
    Dir.chdir(PUPPETSERVER_SUBMODULE) do
      sh 'lein install'
    end
  end
end

namespace :build do
  desc 'Build the facts_upload JAR'
  task :jar do
    sh 'lein with-profile +puppet-module jar'
  end

  desc 'Build the facts_upload Module'
  task :module => FACTS_UPLOAD_MODULE_SRCS do
    sh 'puppet module build'
  end
end

namespace :test do
  desc 'Run leiningen integration tests'
  task :integration => PUPPETSERVER_JAR do
    sh 'lein test :integration'
  end
end

directory PUPPETSERVER_SUBMODULE do
  sh 'git submodule update --init --recursive'
end

directory PUPPETSERVER_JAR => PUPPETSERVER_SUBMODULE do
  Rake::Task['puppetserver:install'].invoke
end

file FACTS_UPLOAD_JAR => FACTS_UPLOAD_JAR_SRCS do
  Rake::Task['build:jar'].invoke
end

directory 'files/'

file 'files/facts-upload.jar' => ['files/', FACTS_UPLOAD_JAR] do
  cp FACTS_UPLOAD_JAR, 'files/facts-upload.jar'
end

file FACTS_UPLOAD_MODULE => FACTS_UPLOAD_MODULE_SRCS do
  Rake::Task['build:module'].invoke
end