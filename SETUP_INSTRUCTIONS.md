# Setup Instructions

## Prerequisites

1. OpenNebula CLI tools installed (`onevm`, `oneuser`, etc.)
2. Access to OpenNebula endpoint: `https://grid5.mif.vu.lt/cloud3/RPC2`
3. Team member OpenNebula accounts with credentials

## Configuration Steps

### 1. Configure Team Members

Edit `config/team_members.conf` and replace the placeholder passwords with actual team member passwords:

```bash
# Format: username:password:endpoint:template
TEAM_MEMBER_1=user1:actual_password1:https://grid5.mif.vu.lt/cloud3/RPC2:ubuntu-24.04
TEAM_MEMBER_2=user2:actual_password2:https://grid5.mif.vu.lt/cloud3/RPC2:ubuntu-24.04
TEAM_MEMBER_3=user3:actual_password3:https://grid5.mif.vu.lt/cloud3/RPC2:ubuntu-24.04
TEAM_MEMBER_4=user4:actual_password4:https://grid5.mif.vu.lt/cloud3/RPC2:ubuntu-24.04
```

**Important**: 
- Replace `user1`, `user2`, etc. with actual OpenNebula usernames
- Replace `actual_password1`, `actual_password2`, etc. with actual passwords
- Keep the endpoint and template as shown

### 2. Verify OpenNebula Access

Test that you can access OpenNebula with one of the accounts:

```bash
export ONE_XMLRPC="https://grid5.mif.vu.lt/cloud3/RPC2"
export ONE_AUTH="/tmp/test_auth"
echo "username:password" > $ONE_AUTH
chmod 600 $ONE_AUTH
onevm list
```

### 3. Run Deployment

Once credentials are configured, run the deployment script:

```bash
bash project_start.sh
```

## Authentication Method

The scripts use OpenNebula's `ONE_AUTH` environment variable for non-interactive authentication:

1. Each script creates a temporary `.one_auth_<username>` file with `username:password`
2. Sets `ONE_XMLRPC` environment variable to the OpenNebula endpoint
3. Sets `ONE_AUTH` to point to the temporary auth file
4. Runs OpenNebula commands (no `-u` flag needed)
5. Cleans up the auth file after use

This avoids the interactive password prompt that causes the "Inappropriate ioctl for device" error.

## Troubleshooting

### Error: "Inappropriate ioctl for device"
- **Cause**: OpenNebula CLI trying to prompt for password in non-interactive mode
- **Solution**: Ensure `config/team_members.conf` has correct passwords in format `username:password:endpoint:template`

### Error: "Failed to create VM"
- Check OpenNebula credentials are correct
- Verify OpenNebula endpoint is accessible
- Ensure OpenNebula CLI tools are installed
- Check that the user has permissions to create VMs

### Error: "IMAGE_ID = 0" or "NETWORK_ID = 0"
- These are placeholder values
- You may need to update the VM templates with actual Image ID and Network ID from your OpenNebula instance
- Check available images: `oneimage list`
- Check available networks: `onenetwork list`

