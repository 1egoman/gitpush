inquirer = require "inquirer"
argv = require("minimist") process.argv.slice(2)
{exec} = require "child_process"

class GitPush
  constructor: (@argv) ->

    # get datapoints
    @getRemote (@remote) =>
      @getBranch (@branch, @pushToBranch) =>
        
        if @pushToBranch is @branch
          @pushToBranch = ""
        else
          @pushToBranch = ":#{@pushToBranch}"
        
        cmd = "git push #{@remote} #{@branch}#{@pushToBranch} #{process.argv.slice(2)}"
        console.log "----->", cmd
        exec cmd, (err, out) ->
          console.log err.toString() if err
          console.log out if out.length

  getRemote: (cb) =>
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
    if not (@argv.b or @argv.branch)
      exec "git branch -a", (err, branches) ->
        b = branches.split("\n")
        b = ["master"].concat b if "master" not in b
        inquirer.prompt [
            name: "branch",
            message: "---> branch?"
            type: "list",
            choices: b
          ,
            name: "pushto",
            message: "---> Push To?"
            type: "list"
            choices: ["Same Branch"].concat b
            default: "Same Branch"
          ], (answers) ->
            if answers.pushto is "Same Branch"
              answers.pushto = answers.branch
            cb answers.branch, answers.pushto
    else
      branch = @argv.b or @argv.branch
      cb branch

new GitPush argv