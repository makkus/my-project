# set some environment variables depending on whether this is a ci run for a tag

if [ -z "$CI_COMMIT_TAG" ];
then
  export UPLOAD_PROJECT_ID="$CI_PROJECT_ID"
else
  # TODO: check other variables
#  export UPLOAD_PROJECT_ID="24022281"
   export UPLOAD_PROJECT_ID="$CI_PROJECT_ID"
fi
