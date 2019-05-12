#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TARGET=$1

if [[ $TARGET == clean || $TARGET == distclean ]]; then
	CLEAN_MODE=0
else
	CLEAN_MODE=1
fi

CONFIG='--prefix=/mnt/opt/privateer'

if [[ ! -d $DIR/downloads ]]; then
	mkdir $DIR/downloads
fi

if [[ $TARGET == arm ]]; then
	cd $DIR/downloads && [[ ! -f arm_v7_vfp_le.tar.xz ]] && wget https://github.com/McBane87/samy-gvfs-bs/raw/master/downloads/arm_v7_vfp_le.tar.xz
	[[ ! -d $DIR/toolchain ]] && mkdir -p $DIR/toolchain
	cd $DIR/toolchain && [[ ! -d $DIR/toolchain/arm_v7_vfp_le ]] && tar -xJf $DIR/downloads/arm_v7_vfp_le.tar.xz	
	CONFIG=" $CONFIG --host=armv7fl-montavista-linux-gnueabi"
	SYSROOT="--sysroot=$DIR/toolchain/arm_v7_vfp_le/target"
	export PATH=$DIR/toolchain/arm_v7_vfp_le/bin:$PATH
elif [[ $TARGET == mips ]]; then
	cd $DIR/downloads && [[ ! -f mips24ke_nfp_be.tar.xz ]] && wget https://github.com/McBane87/samy-gvfs-bs/raw/master/downloads/mips24ke_nfp_be.tar.xz
	[[ ! -d $DIR/toolchain ]] && mkdir -p $DIR/toolchain
	cd $DIR/toolchain && [[ ! -d $DIR/toolchain/mips24ke_nfp_be ]] && tar -xJf $DIR/downloads/mips24ke_nfp_be.tar.xz	
	CONFIG="$CONFIG --host=mips-montavista-linux-gnu"
	SYSROOT="--sysroot=$DIR/toolchain/mips24ke_nfp_be/target"
	export PATH=$DIR/toolchain/mips24ke_nfp_be/bin:$PATH
elif [[ $CLEAN_MODE -ne 0 ]]; then
	echo "ERROR: Missing Target [arm|mips|clean]"
	exit 1
fi

cd $DIR/ && \


if [[ ! -f $DIR/logrotate/.patched && $CLEAN_MODE -ne 0 ]]; then
	cd $DIR && patch -bp0 < logrotate_perm.patch && \
	touch $DIR/logrotate/.patched
elif [[ $CLEAN_MODE -eq 0 && -f $DIR/logrotate/.patched ]]; then
	cd $DIR && patch -bRp0 < logrotate_perm.patch && \
	rm -f $DIR/logrotate/.patched
fi

if [[ ! -d $DIR/package/$TARGET ]]; then
	mkdir -p $DIR/package/$TARGET
else 
	rm -rf $DIR/package/$TARGET/*
fi

if [[ $CLEAN_MODE -eq 0 ]]; then
	cd $DIR/popt-1.16 && \
		make clean ; make distclean ; rm -rvf $DIR/popt-1.16/OUT
	
	cd $DIR/logrotate && \
		make clean ; make distclean
	
	rm -rf $DIR/package/*
else
	cd $DIR/popt-1.16 && \
		./configure \
			$CONFIG \
			CFLAGS="$SYSROOT" \
		&& \
		make && \
		make DESTDIR=$DIR/popt-1.16/OUT install

	cd $DIR/logrotate && \
		autoreconf -fiv && \
		./configure \
			$CONFIG \
			--with-compress-command=/mnt/opt/privateer/usr/bin/gzip \
			--with-uncompress-command=/mnt/opt/privateer/usr/bin/gunzip \
			--with-default-mail-command=/mnt/opt/privateer/usr/bin/mail \
			--with-state-file-path=/dtv/logrotate.status \
			CFLAGS="$SYSROOT -I $DIR/popt-1.16/OUT/mnt/opt/privateer/include -Wl,-L $DIR/popt-1.16/OUT/mnt/opt/privateer/lib" \
			LDFLAGS="-L $DIR/popt-1.16/OUT/mnt/opt/privateer/lib" \
			LIBS="$DIR/popt-1.16/OUT/mnt/opt/privateer/lib/libpopt.a" \
			--without-acl \
			--without-selinux \
		&& \
		sed -i 's/-lpopt//g' Makefile && \
		make && \
		make DESTDIR=$DIR/package/$TARGET install && \
		cp -ra $DIR/misc/* $DIR/package/$TARGET/mnt/ && \
		rm -rf $DIR/package/$TARGET/mnt/opt/privateer/share && \
		cd $DIR/package/$TARGET/ && tar -vczf $DIR/logrotate_samy_$TARGET.tar.gz *
fi
		


