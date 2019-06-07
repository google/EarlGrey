if [ -d "Submodules" ]; then
    echo "Already cloned submodules. Delete the submodules directory to re-clone submodules."
else
    echo "Submodules does not exist, cloning submodules."
    git clone https://github.com/facebook/fishhook Submodules/fishhook
    git clone https://github.com/google/eDistantObject Submodules/eDistantObject
fi

