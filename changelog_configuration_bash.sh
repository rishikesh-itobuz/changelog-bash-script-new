


# check if package.json file is present

MyFile=package.json
if [ -f "$MyFile" ]; then
  # check git is present in the project or not
  if [ -d .git ]; then
      echo ""
  else
      echo "INITIALIZING A NEW GIT REPROSETORY"
      git init
  fi
  # taking input for non interactive terminal
  project_id="$1"
  response="$2"
  using_typescript="$3"
  use_pre_commit_lint="$4"
  lint_script_command="$5"
  issue_id="$6"

  # taking input for interactive terminal
  # read -r -p "Please provide the Project Id: " project_id
  # read -r -p "Please provide the Current issue Id: " issue_id
  # read -r -p "Are you using npm? [y/N] " response
  # read -r -p "Are you using typescript? [Y/n] " using_typescript
  # read -r -p "Do you want to run lint using husky pre-commit hook  ? [Y/n] " use_pre_commit_lint
  
  case "$use_pre_commit_lint" in
    [nN][oO]|[nN]) 
        echo
        ;;
    *)
        read -r -p "provide the script used for running lint: " lint_script_command
        if [ "$lint_script_command" ]; then
          echo ""
        else
          lint_script_command=lint
        fi
        
esac
  ## function to add script in package.json
  update_scripts_section() {
    local new_script="$1"
    local file_name="package.json"
    
    # Check if the file contains the "scripts" section
    if grep -q '"scripts"' "$file_name"; then
        # If "scripts" section exists, update it
        sed -i.bak 's/"scripts": {/"scripts": {'"$new_script"',/' "$file_name"
    else
        # If "scripts" section does not exist, add it
        sed -i.bak 's/\(.*\)/\1, "scripts": {'"$new_script"'}/' "$file_name"
    fi
    
    # Remove backup file created by sed
    rm "$file_name".bak
}

  # function to create commitlint.config
  create_commitlint_config() {
cat <<EOF > "$1"
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [0],
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
    'validate-commit-message': [2, 'always'],
  },
  plugins: [
    {
      rules: {
        'validate-commit-message': ({ subject }) => {
          if (/^$project_id-\d+\s.*$/.test(subject)) {
            return [true];
          }
          return [
            false,
            \`Please provide a valid Commit message pattern : '<type>: [$project_id-<ISSUE_ID>] <commit-message>'.\`,
          ];
        },
      },
    },
  ],
};
EOF
}
  

    # if package manager is npm
    case "$response" in
    [yY][eE][sS]|[yY]) 
        echo "======================== using npm ========================"
        echo "********************* PACKAGES INSTALLATION STARTS *********************"
        npm install --save-dev @commitlint/{cli,config-conventional} husky @digitalroute/cz-conventional-changelog-for-jira standard-version
        echo "+++++++++++++++++++++ PACKAGES INSTALLATION DONE +++++++++++++++++++++"

        echo "********************* HUSKY CONFIGURATION STARTS *********************"

        npx husky init
        echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
        case "$use_pre_commit_lint" in
         [nN][oO]|[nN]) 
           echo "" > .husky/pre-commit
          ;;
        *)
          echo "npm run $lint_script_command" > .husky/pre-commit;;
        esac

        echo "+++++++++++++++++++++ HUSKY CONFIGURATION DONE +++++++++++++++++++++"
        ;;
    *)
    # if package manager is yarn
        echo "======================== using yarn ========================"
        # installing the required packeges
        echo "********************* PACKAGES INSTALLATION STARTS *********************"
        yarn add --dev @commitlint/{cli,config-conventional} husky @digitalroute/cz-conventional-changelog-for-jira standard-version
        echo "+++++++++++++++++++++ PACKAGES INSTALLATION DONE +++++++++++++++++++++"

        echo "********************* HUSKY CONFIGURATION STARTS *********************"

        yarn husky init
        echo "yarn commitlint --edit \$1" > .husky/commit-msg
        case "$use_pre_commit_lint" in
         [nN][oO]|[nN]) 
           echo "" > .husky/pre-commit
          ;;
        *)
          echo "yarn $lint_script_command" > .husky/pre-commit;;
        esac

        echo "+++++++++++++++++++++ HUSKY CONFIGURATION DONE +++++++++++++++++++++"
        
     esac
# configuring Commitlint
echo "======================== Creating commitlint.config for commitlint  ========================"
 case "$using_typescript" in
    [nN][oO]|[nN]) 
        create_commitlint_config 'commitlint.config.js'
        ;;
    *)
        create_commitlint_config 'commitlint.config.ts'
        
esac
## configuring Commitizen
echo ">>>>>>>>>>>>>>>>>>>>>>>>> Creating .czrc for commitzen >>>>>>>>>>>>>>>>>>>>>>>>>"
cat <<EOF > ".czrc"
{
  "path": "./node_modules/@digitalroute/cz-conventional-changelog-for-jira",
  "maxHeaderWidth": 120
}
EOF

## updating script in package.json
echo "########################### Updating scripts in package.json ###########################"
update_scripts_section '"commit": "git-cz"'
update_scripts_section '"release": "standard-version"'
update_scripts_section '"prerelease": "yarn standard-version -- --prerelease"'
update_scripts_section '"minor:release": "yarn standard-version -- --release-as minor"'
update_scripts_section '"major:release": "yarn standard-version -- --release-as major"'
update_scripts_section '"patch:release": "yarn standard-version -- --release-as patch"'

echo "---------------------Commited the changes as:- feat: $project_id-$issue_id changelog configuration setup done"
git add .
git commit -m "feat: $project_id-$issue_id changelog configuration setup done"





else 
echo "$MyFile does not exist."
fi
