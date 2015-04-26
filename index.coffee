##############################
### PH - a better git push ###
##############################

inquirer = require "inquirer"
{exec} = require "child_process"
chalk = require "chalk"

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

    # get datapoints
    @getRemote (@remote) =>
      @getBranch (@branch, @pushToBranch) =>
        
        # allow supported switches
        switches = "fvqn".split ''
        extra = (switches.map (s) -> "-#{s}" if s in args.join " ").join " "


        if @pushToBranch is @branch or not @pushToBranch
          @pushToBranch = ""
        else
          @pushToBranch = ":#{@pushToBranch}"
        
        # log the command we are about to run
        console.log [
          "----->"
          "git"
          "push"
          chalk.magenta @remote
          "#{chalk.cyan @branch}#{chalk.bgBlue @pushToBranch}"
          extra
        ].join " "

        # and, run it!
        exec "git push #{@remote} #{@branch}#{@pushToBranch} #{extra}", (err, out) ->
          if err
            e = err.toString()
            console.log e

          console.log out if out.length
          if err
            console.log chalk.red "Error!"
          else
            console.log chalk.green "Success!"

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
        
        # construct branch array and find
        # current branch
        b = branches.trim("\n").split("\n").map (b) -> 
          if b[0] is "*" then currentBranch = b.slice(2)
          b.slice(2)

        return cb currentBranch if @argv.c

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
new GitPush argv