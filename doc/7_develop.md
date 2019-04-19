#### [Home](../README.md)
## Notes for bashbot developers
This section is about help and best pratices for new bashbot developers. The main focus on is creating new versions of bashbot, not on develop your individual bot. Nevertheless the rules and tools described here can also help you with your bot development.

bashbot development is done on github. If you want to provide fixes or new features [fork bashbot on githup](https://help.github.com/en/articles/fork-a-repo) and provide changes as [pull request on github](https://help.github.com/en/articles/creating-a-pull-request).

### Setup your develop environment

1. install git, install [shellcheck](5_practice.md#Test-your-Bot-with-shellcheck)
2. setup your [environment for UTF-8](4_expert.md#Setting-up-your-Environment)
3. clone your bashbot fork to a new directory ```git clone https://github.com/<YOURNAME>/telegram-bot-bash.git```, replace ```<YOURNAME>``` with your username on github
4. create and change to your develop branch ```git checkout -b <YOURBRANCH>```, replace ```<YOURBRANCH>``` with the name you want to name it, e.g. 'develop'
5. give your (dev) fork a new version tag: ```git tag vx.xx```, version must be higher than current version
6. setup github hooks by running ```dev/install-hooks.sh``` (optional)

### Versioning

Bashbot is tagged with version numbers. If you start a new development cycle you must tag your fork with a version higher than the current version.
E.g. if you fork 'v0.60' the next develop version should tagged as ```git tag "v0.61-dev"``` for fixes or ```git tag "v0.70-dev"``` for new features.

To get the current version name of your develepment fork run ```git describe --tags```. The output looks like ```v0.70-dev-6-g3fb7796``` where your version tag is followed by the number of commits since you tag your branch and followed by the latest commit hash. see also [comments in version.sh](../dev/version.sh)

To update the Version Number in your scripts run ```dev/version.sh```, it will update the line '#### $$VERSION$$ ###' in all files to the current version name.

If you actived git hooks in Setup step 6, 'version.sh' updates the version name on every push

### Shellchecking

For a shell script running as a service it's important to be paranoid about quoting, globbing and other common problems. So it's a must to run shellchek on all shell scripts before you commit a change. this is automated by a git hook activated in Setup step 6.

In addition you can run ```dev/hooks/pre-commit.sh``` every time you want to shellcheck all files given in 'dev/shellcheck.files'.


#### [Prev Function Reference](6_function.md)

#### $$VERSION$$ v0.61-2-gfd4dd8c
