# Contentful Shell

[![npm version](https://badge.fury.io/js/contentful-shell.svg)](https://badge.fury.io/js/contentful-shell)

Contentful Shell is a shell script wrapper for managing a Contentful space in your
rails project.  It's primary purpose is to set appropriate command line flags when
calling into the [Contentful CLI](https://github.com/contentful/contentful-cli),
based on your environment variables.  It is especially useful when combined with
[direnv](https://direnv.net/).

```
▶ bin/contentful help
bin/contentful <command> [opts]
  Commands:
    init
      Installs the required dependencies into your rails project

    migrate [dir|file]
      runs pending migration files in the given directory
        * [dir|file] (optional) - Default: db/migrate

    compare [env]
      Downloads content types and editor interfaces from the given environment
      and compares the structure to the one stored in db/contentful-schema.json.
      If they are different, exits -1 and prints the diff.

    backup [file]
      downloads a backup of the current space to the given file
        * [file] (optional) - default: timestamped file in current directory

    extract <id> [depth] [file]
      downloads the specified entry and all entries & assets that it links to
      down to the specified depth.  The result is a file that can be passed to
      Contentful Import.
      If the file specified is '-', each entry is printed as a stream to STDOUT.
      This makes it easy to pipe to jq.
        * <id> (required) - The ID of the entry to extract
        * [depth] (optional) - Default: 10

    delete
      Creates a backup and then deletes an environment.

    wipe
      Deletes all data in an environment.  You should have a clean environment
      with no entries or content types after this operation.

    restore [file]
      restores a given backup file into the current space
        * [file] (optional) - default: the most recent backup file in the current directory

    new_env
      deletes the current working environment if it exists and makes a new clone of 'master'.
        * -e [to environment ID] (optional) - the current working environment.  Default: $USER

    generate [name]
      Creates a sample migration in the db/migrate directory
        * [name] (optional) - default: 'contentful_migration'

    env
      Displays your current configured environment

    checkout [env]
      Sets your current working environment if it exists. If it does not, will ask if you'd like to create from 'master.'
        * [env] (optional) - default: $CONTENTFUL_ENVIRONMENT
        * -e [to environment ID] (optional) - the current working environment.

  Flags:
      y) # Yes - skip prompts
      s) # Contentful Space ID - overrides env var CONTENTFUL_SPACE_ID
      a) # Contentful Mgmt Token - overrides env var CONTENTFUL_MANAGEMENT_TOKEN
      t) # Contentful access Token - overrides env var CONTENTFUL_ACCESS_TOKEN
      e) # Contentful environment ID - overrides env var CONTENTFUL_ENVIRONMENT
      o) # Output file - a filename to write output to
      p) # Preview mode - hit the contentful preview API instead of the CDN
      v) # Verbose mode - extra output
      h) # Display help.

  Examples:
    bin/contentful migrate -y -s 1xab -a $MY_TOKEN db/migrate/20180101120000_add_content_type_dog.ts
    bin/contentful backup -s 1xab -a $MY_TOKEN 2018_01_01.1xab.dump.json
    bin/contentful extract -o page-awaken.json 6174ivkv4Iy6eoguOoacC0 10
    bin/contentful import page-awaken.json --skip-content-publishing
    bin/contentful extract -p $CONTENTFUL_PREVIEW_ACCESS_TOKEN -v 6174ivkv4Iy6eoguOoacC0 - | jq -r .sys.id
    bin/contentful restore -y -s 1xab -a $MY_TOKEN 2018_01_01.1xab.dump.json
    bin/contentful delete -s 1xab -a $MY_TOKEN -e env
    bin/contentful new_env -e gordon_dev
    bin/contentful generate add content type dog
```

## Installation

```
npm install contentful-shell
```

After installation, your Rails project's `bin` directory should have the `contentful`
script, along with a `release` script which calls `bin/contentful migrate -y`.  Your
`Procfile` should also be configured with a release command - this is how Heroku
calls your release commands whenever you deploy your app.  You should check-in the
changes to your release script and procfile.

## Usage

The best way to use this script is with [direnv](https://direnv.net/).  Create
a `.envrc` file to set the appropriate Contentful tokens for your space:

```
export CONTENTFUL_ACCESS_TOKEN=xxxxx
export CONTENTFUL_SPACE_ID=xxxxx
export CONTENTFUL_MANAGEMENT_TOKEN=CFPAT-xxxxx
export CONTENTFUL_ENVIRONMENT=staging

```

then `direnv allow` to load those variables into your terminal whenever you change
directory.  From this point on, `bin/contentful` will use those environment
variables to access the appropriate space and environment for all operations.

## Migrations

As stated earlier, the installation adds `bin/contentful migrate -y` to your
`bin/release` script.  This uses the [Watermark Church fork of Contentful Migrations CLI](https://github.com/watermarkchurch/contentful-migration)
in order to run all Contentful migrations inside your `db/migrate` directory.  Any
previously-run migrations will be skipped.  This tool creates a new content type
in your space in order to track the results of running migrations.

We have found this workflow to be very effective in managing changes to a Contentful space.
We hope you will agree!
