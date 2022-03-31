# Always call this from within the EarlGrey repository.
EARLGREY_ROOT_DIR=$(git rev-parse --show-toplevel)
if [ -d $EARLGREY_ROOT_DIR/"Submodules" ]; then
    echo "Already cloned submodules. Delete the submodules directory to re-clone submodules."
else
    echo "Submodules does not exist, cloning submodules."
    git clone https://github.com/google/eDistantObject $EARLGREY_ROOT_DIR/Submodules/eDistantObject
fi
