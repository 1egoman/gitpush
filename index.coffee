##############################
### PH - a better git push ###
##############################

inquirer = require "inquirer"
{exec, spawn} = require "child_process"
{exists} = require "fs"
chalk = require "chalk"
pkg = require "./package.json"
_ = require "underscore"

# set up args and append a dash if the user
# omited one
args = process.argv.slice(2).join ' '
args = "-#{args}" if args[0] isnt '-'
args = args.split " "
argv = require("minimist") args

class GitPush
  constructor: (@argv) ->
    # help?
    if @argv.help or @argv['?']
      console.log @help()
      return

    # version?
    if @argv.v or @argv.version
      console.log """
      ph - version #{chalk.cyan pkg.version}
      Run #{chalk.blue "--help"} for help
      """
      return

    # push or pull?
    # inquirer.prompt [
    #   name: "action",
    #   message: "---> push/pull?"
    #   default: "push",
    #   type: "list",
    #   choices: ["push", "pull"]

    # ], (answers) =>
    #   action = answers.action

    if @argv.pull then action = "pull" else action = "push"

    # get datapoints
    @getRemote (@remote) =>
      @getBranch (@branch, @pushToBranch) =>

        # allow supported switches
        # also, add all of the > 1 char switches except for the ones specified
        keepFlags = ["_", "pull", "remote", "branch", "origin", "current-branch", "f", "v", "q", "n", "o", "h", "p", "m", "d", "c"]
        extra = Object.keys(@argv).map (k) =>
          if k not in keepFlags
            if typeof @argv[k] is "boolean"
              "--#{k}"
            else
              "--#{k} #{@argv[k]}"
          else
            ""

        extra = extra.join(" ").trim " "


        if @pushToBranch is @branch or not @pushToBranch
          @pushToBranch = ""
        else
          @pushToBranch = ":#{@pushToBranch}"

        # log the command we are about to run
        console.log [
          "----->"
          "git"
          action
          chalk.magenta @remote
          "#{chalk.cyan @branch}#{chalk.bgBlue @pushToBranch}"
          extra
        ].join " "

        # and, run it!
        child = spawn "git", _.compact([action, @remote, @branch, @pushToBranch, extra])

        onData = (buffer) ->
          s = buffer.toString()

          # colorize messages
          s = "-----> #{chalk.green s}" if s.indexOf("up-to-date") isnt -1
          s = "-----> #{chalk.red s}" if s.indexOf("fatal: ") isnt -1

          console.log s.trim '\n'

        child.stdout.on 'data', onData
        child.stderr.on 'data', onData


  getRemote: (cb) =>
    return cb "origin" if @argv.o or @argv.origin
    return cb "heroku" if @argv.h or @argv.heroku
    return cb "production" if @argv.p or @argv.prod

    if not (@argv.r or @argv.remote)
      exec "git remote", (err, remotes) ->
        r = remotes.trim("\n").split "\n"
        inquirer.prompt [
          name: "remote",
          message: "---> remote?"
          default: "origin",
          type: "list",
          choices: r

        ], (answers) ->
          remote = answers.remote
          cb remote
    else
      remote = @argv.r or @argv.remote
      cb remote

  getBranch: (cb) =>
    currentBranch = "master"

    return cb "master" if @argv.m or @argv.master
    return cb "dev" if @argv.d or @argv.dev

    if not (@argv.b or @argv.branch)
      exec "git branch", (err, branches) =>

        # construct branch array and find current branch
        b = branches.trim('\n').split('\n').map (b) ->
          if b[0] is "*"
            currentBranch = b.slice(2)
            currentBranch
          else
            b

        return cb currentBranch if @argv.c or @argv["current-branch"]

        b = ["master"].concat b if "master" not in b
        inquirer.prompt [
            name: "branch",
            message: "---> branch?"
            type: "list",
            choices: b
            default: currentBranch
          ,
            name: "pushto",
            message: "---> to which remote branch?"
            type: "list"
            choices: b
            default: currentBranch
          ], (answers) ->
            cb answers.branch, answers.pushto
    else
      branch = @argv.b or @argv.branch
      cb branch

  help: ->
    """
    Usage: ph [options]
    #{chalk.yellow "-f, -v, -q, -n"} are the same as git push, normally.

    == Branch Choices ==
    #{chalk.cyan "-m"} branch = master
    #{chalk.cyan "-d"} branch = dev
    #{chalk.cyan "-c"} branch = currently active branch

    == Remote Choices ==
    #{chalk.magenta "-o"} remote = origin
    #{chalk.magenta "-h"} remote = heroku
    #{chalk.magenta "-p"} remote = production

    Anything not specified is prompted for by the app.

    == Examples ==
    #{chalk.blue "ph c"} ask for the remote but push to the current branch.
    #{chalk.blue "ph oc"} push to origin the current branch.
    #{chalk.blue "ph hm"} push to heroku the master branch.
    """

exports.GitPush = GitPush

# and, check to make sure this is a git repo
exists "./.git", (doesit) ->
  if doesit
    new GitPush argv
  else
    console.log chalk.red "This isn't a git repo!"
