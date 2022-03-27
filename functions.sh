function assume_role() {
    aws_out=$(aws sts assume-role --role-arn "${1}" --role-session-name ${2});

    if [[ -z "$aws_out" ]]; then
        echo "No role credentials received, no variables set"
        return;
    fi

    export AWS_ACCESS_KEY_ID=$(echo $aws_out | jq -r .Credentials.AccessKeyId);
    export AWS_SECRET_ACCESS_KEY=$(echo $aws_out | jq -r .Credentials.SecretAccessKey);
    export AWS_SESSION_TOKEN=$(echo $aws_out | jq -r .Credentials.SessionToken);

    echo "role ${1} assumed successfully"
    echo
    echo "actions will be performed by the following user:"
    echo
    echo $aws_out | jq -r .AssumedRoleUser.AssumedRoleId
    echo $aws_out | jq -r .AssumedRoleUser.Arn
    echo
    echo "session expires at $(echo $aws_output | jq -r .Credentials.Expiration)"
}

function rotate_key() {
    # get the specified profile's current key/secret
    rotate_id=$(grep -F "[$1]" -A 2 <path_to_credentials> | grep -F "aws_access_key_id" | awk '{print $3}')
    rotate_secret=$(grep -F "[$1]" -A 2 <path_to_credentials> | grep -F "aws_secret_access_key" | awk '{print $3}')

    if [[ -z $rotate_id ]]; then
        echo "rotate_id unset, aborting..."
        return
    fi
    if [[ -z $rotate_secret ]]; then
        echo "rotate_secret unset, aborting..."
        return
    fi

    # retain current profile setting, then set profile to rotation target profile
    starting_profile=$AWS_PROFILE
    export AWS_PROFILE=$1

    new_key=$(aws iam create-access-key)
    new_id=$(echo $new_key | jq -r '.AccessKey.AccessKeyId')
    new_secret=$(echo $new_key | jq -r '.AccessKey.SecretAccessKey')

    if [[ -z $new_id ]]; then
        echo "new_id unset, aborting..."
        return
    fi
    if [[ -z $new_secret ]]; then 
        echo "new_secret unset, aborting..."
        return
    fi

    now=$(date)

    # save previous credentials in case something goes horribly wrong and you end up with blank credentials (optional; another alternative is not appending the date so you only store the most recent creds for that profile)
    echo "[$1]\naws_access_key_id = ${rotate_id}\naws_secret_access_key = ${rotate_secret}" > "/tmp/.aws/$1_${now}"

    aws iam update-access-key --access-key-id $rotate_id --status Inactive
    aws iam delete-access-key --access-key-id $rotate_id
    echo "deleted key $1 - ${rotate_id} successfully"

    sed -i '' s~$rotate_id~new_id~ <path_to_credentials>
    sed -i '' s~$rotate_secret~new_secret~ <path_to_credentials>
    echo "successfully replaced key and secret pair: \n$rotate_id\n$rotate_secret\n and set new secret for key $1 - $new_id"
}