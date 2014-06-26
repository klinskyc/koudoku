# this generator based on rails_admin's install generator.
# https://www.github.com/sferik/rails_admin/master/lib/generators/rails_admin/install_generator.rb

require 'rails/generators'

# http://guides.rubyonrails.org/generators.html
# http://rdoc.info/github/wycats/thor/master/Thor/Actions.html

module Koudoku
  class StateMachineGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    # location of our migration files
    source_root File.expand_path('../migrations', __FILE__)

    desc "Upgrades existing installations with state_machine features"

    def add_state_machine
      copy_migration "create_notify_user_notifications"
      say "run rake db:migrate"
    end

  end
end


