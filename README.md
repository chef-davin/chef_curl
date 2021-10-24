# chef_curl
A script for accessing the Chef Infra Server API using Bash and not using Knife or Ruby.

## Dependencies

- curl
- openssl
- awk
- jq

## Usage

chef_curl.sh [options] API_PATH

Options:

- `-h`: Display this help message
- `-s`: Chef Server URL
- `-u`: Chef user name
- `-p`: Chef User PEM file path
- `-c`: CACert Path (defaults to /etc/chef/embedded/ssl/certs/cacert.pem)
- `-v`: Chef client version declaration (defaults to 17.6.18)
- `-X`: REST Method to use (i.e. GET, PUT, POST). Defaults to GET
- `-d`: REST message body (used with POST and PUT methods)

## Making things easier

After cloning the script, edit the variables on lines 5 through 11 to set your chef server and user defaults. With this, you won't need to use as many of the command line options except for `-X` and `-d`
