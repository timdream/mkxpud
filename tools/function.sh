function usage {

	echo "Usage: 
 mkxpud <option> [<project codename>] - Image Generator for xPUD

Options:
	all		Execute the whole process of creating a project image
	clean		Removes most generated files
	image		Genreate image from the working directory
	test		Invoke 'QEMU' to test image with bundled kernel 
	help		Display this help

For further informations please refer to README file."
}

function clean {
	sudo rm -rf working/$MKXPUD_CODENAME deploy/$MKXPUD_CODENAME
}

function setup {

	echo "[mkxpud] Setup Project: $1"
	MKXPUD_CODENAME=$1
	mkdir -p working/$MKXPUD_CODENAME
	mkdir -p deploy/$MKXPUD_CODENAME
	export MKXPUD_CONFIG=config/$MKXPUD_CODENAME.cookbook
	eval export `./tools/parser $MKXPUD_CONFIG config`

	# copy initramfs skeleton
	cp -rfp --remove-destination skeleton/initramfs/ working/$MKXPUD_CODENAME/initramfs

	# untar rootfs skeleton
	tar zxf skeleton/rootfs.tgz -C working/$MKXPUD_CODENAME/
	export MKXPUD_TARGET=working/$MKXPUD_CODENAME/rootfs

	# copy /dev nodes
	if [ "$MKXPUD_HOST_DEV" == 'true' ]; then
		sudo tar zcf skeleton/archive/dev-host.tgz /dev/*
		sudo tar zxf skeleton/archive/dev-host.tgz -C $MKXPUD_TARGET/
	else 
		sudo tar zxf skeleton/archive/dev.tgz -C $MKXPUD_TARGET/
	fi
	
	# untar default kernel modules if exists
	if [ -e kernel/module/default-module-$MKXPUD_KERNEL.tgz ]; then
		sudo tar zxf kernel/module/default-module-$MKXPUD_KERNEL.tgz -C $MKXPUD_TARGET/
	fi

	echo "[mkxpud] Project Target: $MKXPUD_TARGET"
	
	echo "[mkxpud] Executing pre-build scripts:"
	eval `./tools/parser $MKXPUD_CONFIG prepare`
}

function install {

	echo "    Preparing recipes..."
	for R in `./tools/parser $MKXPUD_CONFIG recipe`; do 
		for P in `./tools/parser package/recipe/$R.recipe package`; do
		PACKAGE="$PACKAGE $P"
		done
	done
	# add OPT packages
	for R in `./tools/parser $MKXPUD_CONFIG opt`; do 
		for P in `./tools/parser package/recipe/$R.recipe package`; do
		PACKAGE="$PACKAGE $P"
		done
	done

	if [ "$MKXPUD_PKGMGR" != 'skip' ]; then
		sudo $MKXPUD_PKGMGR $PACKAGE
	else 
		echo "You need to install following packages according to your cookbook: "
		echo "$PACKAGE"
	fi

}

function strip {

	echo "    Stripping rootfs..."
	for R in `./tools/parser $MKXPUD_CONFIG recipe`; do 
		
		# action 
		eval `./tools/parser package/recipe/$R.recipe action`

		for S in binary data config overwrite; do
		
			for A in `./tools/parser package/recipe/$R.recipe $S`; do
	
			case $S in
				binary) 
						##  host
						cp -rfpl --remove-destination $A $MKXPUD_TARGET/$A
						## ldd-helper
						for i in `./tools/ldd-helper $A`; do 
						
						if [ ! -e $MKXPUD_TARGET/usr/lib/`basename $i` ] && [ ! -e $MKXPUD_TARGET/lib/`basename $i` ]; then
							if [ `dirname $i` == '/usr/lib' ]; then 
							cp -rfpL --remove-destination $i $MKXPUD_TARGET/usr/lib ; 
							else cp -rfpL --remove-destination $i $MKXPUD_TARGET/lib ; fi
						fi
						
						done
					;;
				data) 
						## host 
						[ -d $MKXPUD_TARGET/`dirname $A` ] || mkdir -p $MKXPUD_TARGET/`dirname $A` 
						cp -rfpl --remove-destination $A $MKXPUD_TARGET/$A
					;;
				config) 
						## package/config/*
						[ -d $MKXPUD_TARGET/`dirname $A` ] || mkdir -p $MKXPUD_TARGET/`dirname $A` 
						cp -rfp --remove-destination package/config/$A $MKXPUD_TARGET/$A
					;;
				alternative) 
						## package/alternative/$MKXPUD_CODENAME
						[ -d $MKXPUD_TARGET/`dirname $A` ] || mkdir -p $MKXPUD_TARGET/`dirname $A` 
						cp -rfpL --remove-destination package/alternative/$MKXPUD_CODENAME/$A $MKXPUD_TARGET/$A
					;;
				overwrite) 
						## skeleton/overwrite/
						
						# check binary dependency if the overwrite file is an execute
						if [ -x skeleton/overwrite/$A ] && [ ! -d skeleton/overwrite/$A ]; then
						for i in `./tools/ldd-helper skeleton/overwrite/$A`; do 
						if [ ! -e $MKXPUD_TARGET/usr/lib/`basename $i` ] && [ ! -e $MKXPUD_TARGET/lib/`basename $i` ]; then
							if [ `dirname $i` == '/usr/lib' ]; then 
							cp -rfpL --remove-destination $i $MKXPUD_TARGET/usr/lib ; 
							else cp -rfpL --remove-destination $i $MKXPUD_TARGET/lib ; fi
						fi
						done
						fi
						
						[ -d $MKXPUD_TARGET/`dirname $A` ] || mkdir -p $MKXPUD_TARGET/`dirname $A` 
						cp -rfp skeleton/overwrite/$A $MKXPUD_TARGET/$A
					;;
			esac 
			
			done 
		done 

		# post action 
		eval `./tools/parser package/recipe/$R.recipe post_action`
		
	done

}

function init {

	echo "    Creating initramfs..."
	
		R="initramfs"
		COPY_DESTINATION="working/$MKXPUD_CODENAME/initramfs"
		# action 
		eval `./tools/parser package/recipe/$R.recipe action`

		for S in binary data config overwrite; do
		
			for A in `./tools/parser package/recipe/$R.recipe $S`; do
	
			case $S in
				binary) 
						##  host
						cp -rfpl --remove-destination $A $COPY_DESTINATION/$A
						## ldd-helper
						for i in `./tools/ldd-helper $A`; do 
						
						if [ ! -e $COPY_DESTINATION/usr/lib/`basename $i` ] && [ ! -e $COPY_DESTINATION/lib/`basename $i` ]; then
							if [ `dirname $i` == '/usr/lib' ]; then 
							cp -rfpL --remove-destination $i $COPY_DESTINATION/usr/lib ; 
							else cp -rfpL --remove-destination $i $COPY_DESTINATION/lib ; fi
						fi
						
						done
					;;
				data) 
						## host 
						[ -d $COPY_DESTINATION/`dirname $A` ] || mkdir -p $COPY_DESTINATION/`dirname $A` 
						cp -rfpl --remove-destination $A $COPY_DESTINATION/$A
					;;
				config) 
						## package/config/*
						[ -d $COPY_DESTINATION/`dirname $A` ] || mkdir -p $COPY_DESTINATION/`dirname $A` 
						cp -rfp --remove-destination package/config/$A $COPY_DESTINATION/$A
					;;
				alternative) 
						## package/alternative/$MKXPUD_CODENAME
						[ -d $COPY_DESTINATION/`dirname $A` ] || mkdir -p $COPY_DESTINATION/`dirname $A` 
						cp -rfpL --remove-destination package/alternative/$MKXPUD_CODENAME/$A $COPY_DESTINATION/$A
					;;
				overwrite) 
						## skeleton/overwrite/
						
						# check binary dependency if the overwrite file is an execute
						if [ -x skeleton/overwrite/$A ] && [ ! -d skeleton/overwrite/$A ]; then
						for i in `./tools/ldd-helper skeleton/overwrite/$A`; do 
						if [ ! -e $COPY_DESTINATION/usr/lib/`basename $i` ] && [ ! -e $COPY_DESTINATION/lib/`basename $i` ]; then
							if [ `dirname $i` == '/usr/lib' ]; then 
							cp -rfpL --remove-destination $i $COPY_DESTINATION/usr/lib ; 
							else cp -rfpL --remove-destination $i $COPY_DESTINATION/lib ; fi
						fi
						done
						fi
						
						[ -d $COPY_DESTINATION/`dirname $A` ] || mkdir -p $COPY_DESTINATION/`dirname $A` 
						cp -rfp skeleton/overwrite/$A $COPY_DESTINATION/$A
					;;
			esac 
			
			done 
		done 

		# post action 
		eval `./tools/parser package/recipe/$R.recipe post_action`
}

function opt {

	echo "    Stripping Opt files..."
	for R in `./tools/parser $MKXPUD_CONFIG opt`; do 
		
		# action 
		eval `./tools/parser package/recipe/$R.recipe action`
		
		# create opt directory
		NAME=`./tools/parser package/recipe/$R.recipe name`
		mkdir -p $MKXPUD_TARGET/opt/$NAME

		for S in binary data config overwrite; do
		
			for A in `./tools/parser package/recipe/$R.recipe $S`; do
	
			case $S in
				binary) 
						##  host
						[ -d $MKXPUD_TARGET/opt/$NAME/`dirname $A` ] || mkdir -p $MKXPUD_TARGET/opt/$NAME/`dirname $A`
						cp -rfpl --remove-destination $A $MKXPUD_TARGET/opt/$NAME/$A
						## ldd-helper
						for i in `./tools/ldd-helper $A`; do 
							
							# if not exist in rootfs 
							if [ ! -e $MKXPUD_TARGET/usr/lib/`basename $i` ] && [ ! -e $MKXPUD_TARGET/lib/`basename $i` ]; then
								if [ `dirname $i` == '/usr/lib' ]; then 
								mkdir -p $MKXPUD_TARGET/opt/$NAME/usr/lib;
								cp -rfpL --remove-destination $i $MKXPUD_TARGET/opt/$NAME/usr/lib ; 
								else mkdir -p $MKXPUD_TARGET/opt/$NAME/lib;
								cp -rfpL --remove-destination $i $MKXPUD_TARGET/opt/$NAME/lib ; fi
							fi
							
						done
					;;
				data) 
						## host 
						[ -d $MKXPUD_TARGET/opt/$NAME/`dirname $A` ] || mkdir -p $MKXPUD_TARGET/opt/$NAME/`dirname $A` 
						cp -rfpl --remove-destination $A $MKXPUD_TARGET/opt/$NAME/$A
					;;
				config) 
						## package/config/*
						[ -d $MKXPUD_TARGET/opt/$NAME/`dirname $A` ] || mkdir -p $MKXPUD_TARGET/opt/$NAME/`dirname $A` 
						cp -rfp --remove-destination package/config/$A $MKXPUD_TARGET/opt/$NAME/$A
					;;
				overwrite) 
						## skeleton/overwrite/
						
						# check binary dependency if the overwrite file is an execute
						if [ -x skeleton/overwrite/$A ] && [ ! -d skeleton/overwrite/$A ]; then
						
							if [ ! -e $MKXPUD_TARGET/usr/lib/`basename $i` ] && [ ! -e $MKXPUD_TARGET/lib/`basename $i` ]; then
						
								if [ `dirname $i` == '/usr/lib' ]; then 
								mkdir -p $MKXPUD_TARGET/opt/$NAME/usr/lib;
								cp -rfpL --remove-destination $i $MKXPUD_TARGET/opt/$NAME/usr/lib ; 
								else mkdir -p $MKXPUD_TARGET/opt/$NAME/lib;
								cp -rfpL --remove-destination $i $MKXPUD_TARGET/opt/$NAME/lib ; fi
							
							fi
						fi
						
						[ -d $MKXPUD_TARGET/opt/$NAME/`dirname $A` ] || mkdir -p $MKXPUD_TARGET/opt/$NAME/`dirname $A` 
						cp -rfp skeleton/overwrite/$A $MKXPUD_TARGET/opt/$NAME/$A
					;;
			esac 
			
			done 
		done 

		# post action 
		eval `./tools/parser package/recipe/$R.recipe post_action`
		
	done

}

function kernel {

	echo "[mkxpud] Adding kernel modules"
	
	MKXPUD_CODENAME=$1
	export MKXPUD_CONFIG=config/$MKXPUD_CODENAME.cookbook
	eval export `./tools/parser $MKXPUD_CONFIG config`
	export MKXPUD_TARGET=working/$MKXPUD_CODENAME/rootfs
	
	for MOD in `./tools/parser $MKXPUD_CONFIG module`; do
		for M in `./tools/module-helper $MOD`; do
		
		## FIXME: workaround with different kernel path
		if [ `echo $M | grep "^/"` ]; then
			[ -d $MKXPUD_TARGET/`dirname $M` ] || mkdir -p $MKXPUD_TARGET/`dirname $M` 
			cp -rfpL --remove-destination $M $MKXPUD_TARGET/$M
		else 
			[ -d $MKXPUD_TARGET/$MKXPUD_MOD_PATH/`dirname $M` ] || mkdir -p $MKXPUD_TARGET/$MKXPUD_MOD_PATH/`dirname $M` 
			cp -rfpL --remove-destination $MKXPUD_MOD_PATH/$M $MKXPUD_TARGET/$MKXPUD_MOD_PATH/$M
		fi
		done
	done

	depmod -b $MKXPUD_TARGET $MKXPUD_KERNEL

}

# post 
# FIXME: hook post scripts
function post {

	echo "[mkxpud] Post-install scripts"

	# create symbolic links for /bin/*
	./tools/busybox-helper
	rm $MKXPUD_TARGET/bin/busybox

	# check dependencies of each files under usr/lib and [so_hook] section
	for R in `./tools/parser $MKXPUD_CONFIG recipe`; do 
		for S in `./tools/parser package/recipe/$R.recipe so_hook`; do
		SO_HOOK="$SO_HOOK $MKXPUD_TARGET/$S"
		done
	done
	SO_HOOK="$SO_HOOK "`find $MKXPUD_TARGET/usr/lib/*.so.*`

	for s in $SO_HOOK; do 
		if [ ! -d $s ]; then 
		for i in `./tools/ldd-helper $s`; do 
			if [ ! -e $MKXPUD_TARGET/usr/lib/`basename $i` ] && [ ! -e $MKXPUD_TARGET/lib/`basename $i` ]; then 
			cp -rfpL --remove-destination $i $MKXPUD_TARGET/usr/lib; fi
		done
		fi
	done

	# check dependencies of opt
	SO_HOOK=""
	for O in `./tools/parser $MKXPUD_CONFIG opt`; do 
		for S in `./tools/parser package/recipe/$O.recipe so_hook`; do
		SO_HOOK="$SO_HOOK $MKXPUD_TARGET/opt/$O/$S"
		done
		NAME=`./tools/parser package/recipe/$O.recipe name`
		for s in $SO_HOOK; do 
		if [ ! -d $s ]; then 
		for i in `./tools/ldd-helper $s`; do 
			if [ ! -e $MKXPUD_TARGET/usr/lib/`basename $i` ] && [ ! -e $MKXPUD_TARGET/lib/`basename $i` ]; then 
			cp -rfpL --remove-destination $i $MKXPUD_TARGET/opt/$NAME/usr/lib; fi
		done
		fi
		done
	done

	eval `./tools/parser $MKXPUD_CONFIG action`
	
	# pack binaries with upx 
	if [ -e /usr/bin/upx ]; then 
		for o in `./tools/parser $MKXPUD_CONFIG obfuscate`; do
			upx $MKXPUD_TARGET/$o
		done
	fi

}

function image {

	echo "[mkxpud] Generating image..."
	MKXPUD_CODENAME=$1
	export MKXPUD_CONFIG=config/$MKXPUD_CODENAME.cookbook
	eval export `./tools/parser $MKXPUD_CONFIG config`
	export MKXPUD_TARGET=working/$MKXPUD_CODENAME/rootfs

	# temporary hook for squashfs version 
	if [ `mksquashfs -version | grep '0.4'` ]; then 
		MKSQF="/usr/bin/mksquashfs" 
	else 
		MKSQF="`pwd`/tools/mksquashfs"	
	fi
		
	# enable multi-layered rootfs support for Opts 
	for R in `./tools/parser $MKXPUD_CONFIG opt`; do 
		NAME=`./tools/parser package/recipe/$R.recipe name`
		
		if [ ! -e $MKXPUD_TARGET/opt/$NAME ];then

			mv working/$MKXPUD_CODENAME/$NAME $MKXPUD_TARGET/opt/
			
		fi

			# create .opt file
			cd  $MKXPUD_TARGET/opt/
			$MKSQF $NAME $NAME.opt -noappend 
			cd -
			
			# move opt directory out from rootfs
			mv $MKXPUD_TARGET/opt/$NAME working/$MKXPUD_CODENAME/
		
		cd $MKXPUD_TARGET
			# create the cpio.gz format file to be loaded at boot
			find opt/$NAME.opt | cpio -H newc -o | gzip -9 > ../../../deploy/$MKXPUD_CODENAME/$NAME
			# clean up .opt file 
			rm -f opt/$NAME.opt
		cd -
		
	done
	
	# create compressed rootfs to /opt/rootfs.sqf 
	$MKSQF $MKXPUD_TARGET/ working/$MKXPUD_CODENAME/initramfs/opt/rootfs.sqf -noappend 


	## FIXME: use variable instead of actual initramfs path
	cd working/$MKXPUD_CODENAME/initramfs
	find | cpio -H newc -o > ../../../deploy/$MKXPUD_CODENAME.cpio
	cd -

	for format in `./tools/parser $MKXPUD_CONFIG image`; do 
	
	case $format in
			gz)
				cat deploy/$MKXPUD_CODENAME.cpio | gzip -9 > deploy/$MKXPUD_CODENAME/core
				du -h deploy/$MKXPUD_CODENAME/core
			;;
			iso)
				cp -r skeleton/boot/iso/ deploy/$MKXPUD_CODENAME/
				cp $MKXPUD_KERNEL_IMAGE deploy/$MKXPUD_CODENAME/iso/boot/bzImage
				cp deploy/$MKXPUD_CODENAME/* deploy/$MKXPUD_CODENAME/iso/opt/
				mkisofs -R -l -V 'xPUD' -input-charset utf-8 -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o deploy/$MKXPUD_CODENAME.iso deploy/$MKXPUD_CODENAME/iso/
				rm -rf deploy/$MKXPUD_CODENAME/iso/
				./tools/isohybrid deploy/$MKXPUD_CODENAME.iso
				du -h deploy/$MKXPUD_CODENAME.iso
			;;
			exe)
				cp -r skeleton/boot/exe/ deploy/$MKXPUD_CODENAME/
				cp $MKXPUD_KERNEL_IMAGE deploy/$MKXPUD_CODENAME/exe/bzImage
				cp deploy/$MKXPUD_CODENAME/* deploy/$MKXPUD_CODENAME/exe/
				cd deploy/$MKXPUD_CODENAME/exe/
				makensis xpud-installer.nsi
				cd -
				mv deploy/$MKXPUD_CODENAME/exe/xpud-installer.exe deploy/$MKXPUD_CODENAME.exe
				rm -rf deploy/$MKXPUD_CODENAME/exe/
				du -h deploy/$MKXPUD_CODENAME.exe
			;;
			*)
			echo "$format: not supported format"
			;;
	esac 
	done

}
