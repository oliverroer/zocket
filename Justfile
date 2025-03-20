set quiet

default:
  just --choose

clear:
  clear

build: clear
  zig build

[private]
build-release release: clear
  zig build --release={{release}}

build-release-safe: (build-release "safe")
build-release-fast: (build-release "fast")
build-release-small: (build-release "small")

run:
  zig build run

clean:
  rm -rf .zig-cache zig-out

send-all port message:
  echo "{{message}}" | socat - udp-datagram:255.255.255.255:{{port}},bind=:6666,broadcast,reuseaddr

recv-all port:
  socat - UDP-RECV:{{port}}
