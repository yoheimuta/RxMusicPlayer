setup:bootstrap install-pod

bootstrap:
	# carthage bootstrap --platform iOS --cache-builds
	./carthage.sh bootstrap --platform iOS --cache-builds

update-pod:install-gem
	bundle exec pod repo update
	bundle exec pod install

install-pod:install-gem
	bundle exec pod install

install-gem:
	bundle install --path vendor/bundle
