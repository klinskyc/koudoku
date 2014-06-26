# this generator based on rails_admin's install generator.
# https://www.github.com/sferik/rails_admin/master/lib/generators/rails_admin/install_generator.rb

require 'rails/generators/active_record'

# http://guides.rubyonrails.org/generators.html
# http://rdoc.info/github/wycats/thor/master/Thor/Actions.html

module Koudoku
  class StateMachineGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    # location of our migration files
    source_root File.expand_path('../migrations', __FILE__)

    desc "Upgrades existing installations with state_machine features"

    def add_state_machine
      copy_migration "add_status_to_subscriptions"
      say "run rake db:migrate"
    end

    # This is defined in ActiveRecord::Generators::Base, but that inherits from NamedBase, so it expects a name argument
    # which we don't want here. So we redefine it here. Yuck.
    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        Time.now.utc.strftime("%Y%m%d%H%M%S%L%N")
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end

    protected

    def copy_migration(filename)
      if self.class.migration_exists?("db/migrate", "#{filename}")
        say_status("skipped", "Migration #{filename}.rb already exists")
      else
        migration_template "#{filename}.rb", "db/migrate/#{filename}.rb"
      end
    end

  end


end


