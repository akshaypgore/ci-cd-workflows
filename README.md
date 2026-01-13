## Branching strategy

The repo will maintain below branches
1. feature (can be multiple branches as per features being worked on)
2. develop (single)
3. release (can be multiple depending upon the )
4. master  (single)
5. hotfix  (single)

### Workflow

#### 1. Ideal flow
1. Developer checks out a feature branch from develop. eg: feature/add-user-auth
2. Developer commits the the changes after testing on local and raises a PR to merge in develop.
3. Once the PR to merge in develop is raised, automated tests are executed and branch is merged only if the tests are passed
4. The code is deployed on dev env from the develop branch
5. Once the testing is completed on dev, release manager creates a release branch from develop. eg release/rc-01
6. The code from release/rc-01 is deployed on preprod env
7. Once the testing is completed on preprod env, release manager raises a PR to merge release/rc-01 into master
8. Release manager merges the release/rc-01 into master
9. The code is deployed on production from master branch
10. master is merged back in develop branch


#### 2. Bug encountered on preprod env
1. If a bug is encountered during pre-prod testing
    a. Corresponding release branch is checked out. In this case release/rc-01
    b. A new release branch is checked out from release/rc-01. eg release/rc-02
    c. Bug is fixed and the changes are pushed back to orgign as release/rc-02
    d. The code from release/rc-02 is deployed on preprod env and tesing continues
    e. Once the testing is completed on preprod env
        1. The PR is raised to merge changes in master
        2. Changes are merged back in develop