PROJECT_ROOT = File.dirname(__FILE__)
PUPPETSERVER_SUBMODULE = File.join(PROJECT_ROOT, 'checkouts', 'puppetserver')
# FIXME: Figure out a way to actually find the Jarfile for the currently
# checked out server version. However, this might require invoking lein
# every time rake is invoked --- which is expensive.
PUPPETSERVER_JAR = File.join(PUPPETSERVER_SUBMODULE, 'target')
FACTS_UPLOAD_JAR = File.join(PUPPETSERVER_SUBMODULE, 'target', 'facts-upload.jar')
FACTS_UPLOAD_SRCS = Rake::FileList["src/**/*.clj", "src/**/*.rb"]

namespace :puppetserver do
  desc "Build Puppet Server's JAR and install it to the local mvn repo"
  task :install do
    Dir.chdir(PUPPETSERVER_SUBMODULE) do
      sh 'lein install'
    end
  end
end

namespace :module do
  desc "Build the facts_upload JAR"
  task :jar do
    sh 'lein with-profile +module jar'
  end
end

namespace :test do
  desc "Run leiningen integration tests"
  task :integration => PUPPETSERVER_JAR do
    sh 'lein test :integration'
  end
end

directory PUPPETSERVER_SUBMODULE do
  sh 'git submodule update --init --recursive'
  task :jar do
    Dir.chdir(PUPPETSERVER_SUBMODULE) do
      sh 'lein install'
    end
  end
end

directory PUPPETSERVER_JAR => PUPPETSERVER_SUBMODULE do
  Rake::Task['puppetserver:install'].invoke
end

file FACTS_UPLOAD_JAR => FACTS_UPLOAD_SRCS do
  Rake::Task['module:jar'].invoke
end
