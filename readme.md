# EVL Jukebox Readme

## Installation
### Development
(Use Vagrant, seriously, it does all this for you)
1. Install RVM. ([https://github.com/rvm/rvm](https://github.com/rvm/rvm))
2. Install Ruby 2.2.1 through RVM. `rvm install ruby-2.2.1`
3. Clone from [http://git.evlbr.com/server-management/rails-serverbot](http://git.evlbr.com/server-management/rails-serverbot) and cd into it.
4. Do `rvm-prompt` and make sure it returns `ruby-2.2.1@serverbot`
5. Copy `config/database.yml.example` to `config/database.yml` and configure for the database you'll be using and make sure the correct gem is listed in the `Gemfile`. ([https://gist.github.com/erichurst/961978](https://gist.github.com/erichurst/961978) is a good reference)
6. Run `bundle install` to install Rails, and other dependencies.
7. Run `rake db:setup` to create the tables and insert seed data. This will give you an example HostMachine, ServerImage, Server, and Match to work with.
8. The database is seeded with a HostMachine at localhost, with the user `steam` and the password `serverbotWorker`. Either create this user, or give it another machine to use. (`HostMachine.first.update_attributes(address: "another.host.com", user: "server")` etc in the Rails Console)
9. Install and run Redis on the default port. (6379) [http://redis.io/topics/quickstart](http://redis.io/topics/quickstart)
10. Run `sidekiq-rerun.sh` in a screen or other session. This is the worker that handles long tasks, like downloading the config files, or starting the server. ('long' meaning anything that deals with another machine or that isn't pretty much instant)
11. You can now use the Rails console to run the worker tasks to install steamcmd, download the server image, create and start servers. Don't call the workers directly, instead use the transitions defined in each model. (`HostMachine.first.install_steamcmd!`, be sure to include the exclamation point, this is what triggers the state change to be saved to the database) This will ensure that we keep track of each model's state, and block certain actions if conditions aren't met. (for example, we can't update an image unless all if its servers are stopped)
