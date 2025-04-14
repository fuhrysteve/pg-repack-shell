# pg-repack-shell

Dockerized builds of [pg_repack](https://reorg.github.io/pg_repack/) for multiple PostgreSQL versions.

This project automatically builds tagged images for each supported combination of:

- PostgreSQL ≥ 15 (detected dynamically)
- pg_repack ≥ 1.5.0 (from [PGXN](https://pgxn.org/dist/pg_repack/))

Each image is published as:

```
fuhrysteve/pg-repack-shell:pg<PG_MAJOR>-<PG_REPACK_VERSION>
```

For example:

- `fuhrysteve/pg-repack-shell:pg15-1.5.0`
- `fuhrysteve/pg-repack-shell:pg17-1.5.2`
- `fuhrysteve/pg-repack-shell:latest` → highest PG and pg_repack version

---

## 🔧 Usage

```bash
docker run --rm fuhrysteve/pg-repack-shell:pg15-1.5.2 pg_repack --help
```

---

## 📦 Build Locally

Clone the repo and run:

```bash
make            # install deps, fetch versions, build + tag + push latest
```

Other useful targets:

```bash
make fetch-versions   # Update pg_repack versions (repack_versions.mk)
make build-all        # Build all combinations
make build-missing    # Only build combinations not already pushed
make push-all         # Push all tags
make push-latest      # Tag and push :latest
```

---

## 🛠 Requirements

- Docker
- `jq`, `yq`
- `make`
- Debian/Ubuntu-based OS (or modify `make install` for your distro)

Run `make install` to install dependencies on Debian-based systems.

---

## 🧠 How it Works

- Pulls `pg_repack` versions from PGXN
- Pulls Postgres tags (e.g., `15-bullseye`) from Docker Hub
- Builds a matrix of combinations ≥ the minimums
- Skips builds for tags already on Docker Hub (via `build-missing`)

---

## 🗃 Directory Layout

```text
.
├── Dockerfile.template     # Template used to generate builds
├── Dockerfile              # Generated (ignored)
├── Makefile                # All build logic
├── repack_versions.mk      # Generated list of versions
└── .gitignore
```

---

## 🐳 Example Dockerfile Usage

You can use these images in other containers like:

```dockerfile
FROM fuhrysteve/pg-repack-shell:pg15-1.5.2 as repack

COPY --from=repack /usr/local/bin/pg_repack /usr/local/bin/pg_repack
```

---

## ✍️ License

MIT

---

## 👤 Author

Maintained by [Stephen Fuhry](https://github.com/fuhrysteve)
