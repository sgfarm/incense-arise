YT_PLAYLIST_URL := "https://www.youtube.com/watch?v=rYQ5yXCc_CA&list=PL4kZATn_awL77rh3xUQBWKEj1gNlkv1Zw"
S3_BUCKET_NAME := "sgfarm-incense-arise"
URL_PREFIX := "http://" + S3_BUCKET_NAME + ".s3.us-east-2.amazonaws.com/"

_list:
    @just --list

# downloads YT videos, syncs them to S3, and generates the list
update: download sync write-list

# downloads YT videos from playlist `YT_PLAYLIST_URL` into `./video_cache/`
download:
    -yt-dlp --no-simulate \
        -f "bv+ba/b" \
        -P "./video_cache" \
        -o "%(title)s.%(ext)s" \
        --restrict-filenames \
        --remux-video "mov>mp4/mkv" \
        --embed-subs --sub-langs "en.*" \
        "{{ YT_PLAYLIST_URL }}"

# syncs S3 bucket with `./video_cache/`
sync:
    aws s3 sync video_cache s3://{{ S3_BUCKET_NAME }}/ --delete

# writes an m3u playlist with S3 URLS from `./video_cache/`
write-list:
    ls -1 ./video_cache | sed "s|^|{{ URL_PREFIX }}|g" > playlist.m3u

# builds and runs the server container
container:
	nix build "./#container" && docker load -i result && docker run --rm -p 3000:3000 incense-arise
