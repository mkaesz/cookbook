run:
	docker run -d -p 8088:80 --restart=always --name nginx-file-listing -v /home/mkaesz:/mnt/data nginx-file-listing

build:
	docker image build --tag nginx-file-listing .
