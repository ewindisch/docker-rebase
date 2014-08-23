#!/bin/bash
name=$1; shift

last_id=""
save_dir=$(mktemp -d "/tmp/$name.XXXXXX")
cd $save_dir || exit 1
for layer_id in $@; do
    new_id=$(read -n 16 </dev/urandom | shasum -a 256 - | sed 's/\s*-$//')
    echo "Creating new layer $new_id based on $layer_id"
    echo "Saving old layer ($layer_id)..."
    docker save $layer_id | tar xv
    gsed -i "s/${layer_id}/${new_id}/" $layer_id/json
    if [ -n "$last_id" ]; then
        echo "reparenting"
        gsed -i "s/parent\":\"\w\+/parent\":\"${last_id}/" $layer_id/json
    fi
    mv $layer_id $new_id
    echo "Created new layer ($new_id)"
    last_id=$new_id
done
echo "{\"${name}\":{\"latest\":\"${new_id}\"}}" > repositories
tar c . | docker load
