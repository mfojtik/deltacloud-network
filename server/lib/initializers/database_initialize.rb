# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.

# Initialize the storage layer we use to persist some CIMI entities
# and attributes.
#
# By default the database backend is sqlite3

require 'sequel'
require 'logger'

require_relative '../db'

# We want to enable validation plugin for all database models
#
Sequel::Model.plugin :validation_class_methods

# Enable Sequel migrations extension
Sequel.extension :migration

# For JRuby we need to different Sequel driver
#
sequel_driver = (RUBY_PLATFORM=='java') ? 'jdbc:sqlite:' : 'sqlite://'

# The default sqlite3 database could be override by 'DATABASE_LOCATION'
# environment variable.
#
# For more details about possible values see:
# http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html
#
DATABASE_LOCATION = ENV['DATABASE_LOCATION'] ||
  "#{sequel_driver}#{File.join(BASE_STORAGE_DIR, 'db.sqlite')}"

if RUBY_PLATFORM == 'java'
  require 'jdbc/sqlite3'
  Jdbc::SQLite3.load_driver
end

DATABASE = Deltacloud::initialize_database

# Detect if there are some pending migrations to run.
# We don't actually run migrations during server startup, just print
# a warning to console
#

DATABASE_MIGRATIONS_DIR = File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrations')

unless Sequel::Migrator.is_current?(DATABASE, DATABASE_MIGRATIONS_DIR)
  # Do not exit when this intitializer is included from deltacloud-db-upgrade
  # script
  #
  unless ENV['DB_UPGRADE']
    warn "WARNING: The database needs to be upgraded. Run: 'deltacloud-db-upgrade' command."
    exit(1)
  end
end
