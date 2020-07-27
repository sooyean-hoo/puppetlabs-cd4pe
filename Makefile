echo::
	echo Running as Bash CMD FakeMake
	pwd ;
	execution=`egrep  -h -A100 ^$1    $(dirname $0)/./Makefile  |  egrep -v ^$1  | grep -m 1  -h  -B100 : |    sed -E  's/[$][{](.+)[}]/$\1/g' | sed -E 's/[$]{2}/$/g' ` ; \
	echo Command to Execute @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;  \
	echo "$execution" ; \
	echo Execution @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;   \
	echo "$execution" >  /tmp/test.sh ;  \
	bash  /tmp/test.sh ;   \
	echo Execution DONE@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@; \
	exit 0;

help::	
	@if [ "${t}" = "" ] ; then \
		grep -E "^[a-zA-Z0-9_ ]+[:]+" Makefile   | awk -F":" '{print $$1}'   ; \
	else \
		grep -E "^[a-zA-Z0-9_ ]+[:]+" Makefile   | grep -i "${t}"  | tr ";:\043" " " ;  \
	fi;
	
all:
	pwd ;
	flagDir="/tmp/valentepuppet_$$$$" ; \
	mkdir -p $$flagDir ; \
	find ./  -iname  manifests -type d | while read  line ;  do \
		ppSrc_=$$line     ;\
		ppSrc=`echo  $$ppSrc_| sed 's/[\/\.]/_/g'  ` ; \
		> $$flagDir/$$ppSrc.tmp ;  \
		pushd "$$PWD" ;  cd $$line/.. ;  \
			(  \
			 echo "===================================================================================================In $$(pwd)======="  >> $$flagDir/$$ppSrc.tmp ;  \
			 /opt/puppetlabs/pdk/bin/pdk validate  ${validateOPTS}  2>&1   >> $$flagDir/$$ppSrc.tmp ;   \
			 echo "==============================="   >> $$flagDir/$$ppSrc.tmp ;    \
			 mv -f $$flagDir/$$ppSrc.tmp   $$flagDir/$$ppSrc.log  ; \
			)   &   \
		popd ; \
		sleep 0.25 ; \
	done  ;  \
	\
	find ./  -iname '*.pp' | while read ppSrc ; do \
		ppSrc_=$$ppSrc     ;\
		ppSrc=`echo  $$ppSrc_| sed 's/[\/\.]/_/g'  ` ; \
		> $$flagDir/$$ppSrc.tmp ;  \
		( echo "===================================================================================================parser validate   "$$ppSrc_"=======" >> $$flagDir/$$ppSrc.tmp ; \
		 /usr/local/bin/puppet parser validate   "$$ppSrc_"      2>&1    |    sed -E 's/^[^\(]+\(file: //g' | \
	 	sed  -E 's/^.+control-repo\///g'   2>&1  >> $$flagDir/$$ppSrc.tmp ;  \
	 	mv -f $$flagDir/$$ppSrc.tmp   $$flagDir/$$ppSrc.log   ) & \
	done ; \
	sleep 1 ;   \
 	while [  ! -z "`ls -l $$flagDir/*.tmp `" ] ; do    sleep 50;            done ;   \
	cat $$flagDir/*.log    | sed -E 's/^([^:]+:[^:]+: )(.+)$$/\2 :\1/g'     1>&2 ;   \
	rm -fr $$flagDir 

 
autocorrect::
	echo "===================================================AUTOCORRECT=MODE===================================================================================="
	make all validateOPTS=" -a "

test::
	/opt/puppetlabs/pdk/bin/pdk test unit
	
	
test_serverspec::
	cd  serverspec  && \
		/opt/puppetlabs/pdk/bin/pdk bundle exec rake spec   -v

puppetDoc::
	puppet strings generate  --debug   'lib/**/*.rb' 'manifests/**/*.pp' 'functions/**/*.pp'

puppetClass_print::
	 puppet config print classfile


puppetClass_printall::
	 puppet config print all	 

find_pp::
	find ./ -name '*.pp' -exec awk '/^class [a-zA-Z]/ {print $2}' {} \;

puppetfind_pp::
	puppet doc --outputdir /tmp/puppetdoc --mode rdoc  --modulepath ./       

showtask::
	bolt task show  -module-dir=./

linkAdd_readme:
	cd ./files && \
	ln -s ~/bin/additionalSetup_README 

