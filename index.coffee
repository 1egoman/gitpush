inquirer = require "inquirer"
argv = require("minimist") process.argv.slice(2)
{exec} = require "child_process"
chalk = require "chalk"

class GitPush
  constructor: (@argv) ->

    # get datapoints
    @getRemote (@remote) =>
      @getBranch (@branch, @pushToBranch) =>
        
        # allow supported switches
        switches = "fvqn".split ''
        extra = (switches.map (s) -> "-#{s}" if s in process.argv.slice(2).join " ").join " "


        if @pushToBranch is @branch or not @pushToBranch
          @pushToBranch = ""
        else
          @pushToBranch = ":#{@pushToBranch}"
        
        # log the command we are about to run
        console.log [
          "----->"
          "git"
          "push"
          chalk.yellow @remote
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

    if not (@argv.r or @argv.remote)
      exec "git remote", (err, remotes) ->
        r = remotes.split "\n"
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
        b = branches.split("\n").map (b) -> 
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

new GitPush argv