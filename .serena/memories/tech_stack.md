# Tech Stack

- Primary source: 1C:Enterprise BSL modules plus 1C XML metadata exports; Serena language server: `bsl`; encoding UTF-8.
- Dev environment: Linux amd64 Compose service `dev`, workspace `/workspace`, base image `local/vrunner2:8.3.24.1667`.
- Observed runtime: 1C `8.3.24.1667` under `/opt/1cv8/x86_64/8.3.24.1667`; OneScript `2.1.0`; OPM `1.4.1`; vanessa-runner `2.6.1`.
- `packagedef`: package `moleculer-sidecar-connector` 0.2.0, OneScript environment 2.0.0, dependencies `add`, `vanessa-automation-single`, and pinned `vanessa-runner` 2.6.1.
- Java 21+ is required for Serena's BSL server; shell resolves OpenJDK 21 at `/usr/bin/java` after Bash environment reload.
- `.gitattributes`: BSL, OneScript, XML, and Windows script text use CRLF; shell scripts use LF; 1C artifacts and images are binary.
- Runner defaults in `autumn-properties.json`: file infobase `/F./build/ib`, v8 version selector 8.3, Russian locale/language, managed/thin-client setting `ordinaryapp=-1`.