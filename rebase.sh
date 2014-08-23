#!/bin/bash
name=$1; shift

last_id=""
save_dir=$(mktemp -d "/tmp/$name.XXXXXX")
cd $save_dir || exit 1
for layer_id in $@; do
    #layer_id=$(sed 's/ //g' <<<$layer_id)
    new_id=$(echo $RANDOM | shasum -a 256 - | sed 's/\s*-$//' | sed 's/ //g')
    echo "Creating new layer $new_id based on $layer_id"
    echo "Saving old layer ($layer_id)..."
    docker save $layer_id | tar xv
    gsed -i "s/${layer_id}/${new_id}/g" $layer_id/json
    if [ -n "$last_id" ]; then
        echo "reparenting on $last_id"
        if (grep "parent:" $layer_id/json); then
            echo "Has parent, changing."
            gsed -i "s/parent\":\"\w\+/parent\":\"${last_id}/" $layer_id/json
        else
            echo "Found root-image (no parent). Adding parent id."
            tmpfile=$(mktemp /tmp/${layer_id}.XXXXXXXX)
            python -c "import json; x=json.load(open('${layer_id}/json')); x['parent']='${last_id}'; print json.dumps(x)" > $tmpfile
            mv $tmpfile $layer_id/json
        fi
    fi
    mv $layer_id $new_id
    echo "Created new layer ($new_id)"
    last_id=$new_id
done
echo "Tagging ${name} to ${new_id}"
echo "{\"${name}\":{\"latest\":\"${new_id}\"}}" > repositories
tar c . | docker load
