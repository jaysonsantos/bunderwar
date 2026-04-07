# bunderwar
My up-to date docker images with renovate and arm64/amd64 support

## komga

`komga.Dockerfile` builds a Komga image on top of LinuxServer's Ubuntu base image and s6 overlay. It copies the Komga runtime from `ghcr.io/gotson/komga` and the `rclone` binary from `rclone/rclone`, then runs both under s6.

The image exposes:

- `/config` for Komga state and config
- `/data` for library content
- port `25600`

By default the `rclone` service is disabled and Komga starts normally against local storage under `/data`.

### Google Drive mount

To enable the `rclone mount` sidecar inside the container, set:

- `RCLONE_MOUNT_ENABLED=true`
- `RCLONE_REMOTE=<remote>:<path>`
- `RCLONE_CONFIG_FILE=/config/rclone/rclone.conf` (default)

Optional settings:

- `RCLONE_MOUNT_PATH=/data/gdrive` (default)
- `RCLONE_CACHE_DIR=/config/cache/rclone` (default)
- `RCLONE_EXTRA_ARGS=...`

When `RCLONE_MOUNT_ENABLED=true`, Komga waits for the mountpoint to become a real mount before starting. If `/dev/fuse` is unavailable or the `rclone` config is missing, the container fails loudly instead of serving a broken library path.

The mount requires the usual FUSE container privileges, for example:

- `--device /dev/fuse`
- `--cap-add SYS_ADMIN`
- `--security-opt apparmor:unconfined`

Example:

```bash
docker run -d \
  --name komga \
  -p 25600:25600 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e RCLONE_MOUNT_ENABLED=true \
  -e RCLONE_REMOTE=gdrive:media/comics \
  --device /dev/fuse \
  --cap-add SYS_ADMIN \
  --security-opt apparmor:unconfined \
  -v /path/to/config:/config \
  -v /path/to/data:/data \
  ghcr.io/jaysonsantos/bunderwar:komga-1.23.5
```
