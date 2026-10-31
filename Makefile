.PHONY: setup app-run-linux app-run-android server-dev web-dev test lint build-linux web-build docker-up

setup:
	cd server && npm install
	cd web && npm install
	cd app && flutter pub get && dart run build_runner build -d

app-run-linux:
	cd app && flutter run -d linux

app-run-android:
	cd app && flutter run -d android

server-dev:
	cd server && npm run dev

web-dev:
	cd web && npm run dev

test:
	cd server && npm test
	cd app && flutter test

lint:
	cd server && npm run lint
	cd web && npm run lint
	cd app && flutter analyze

build-linux:
	cd app && flutter build linux --release

web-build:
	cd web && npm run build

docker-up:
	docker compose up --build
