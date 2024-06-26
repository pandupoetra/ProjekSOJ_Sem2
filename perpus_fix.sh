#!/bin/bash

# File penyimpanan data buku
BOOKS_FILE="books.txt"
# File penyimpanan data peminjaman
BORROW_FILE="borrow.txt"
# File untuk mencatat pengembalian
RETURN_FILE="return.txt"

# Fungsi untuk menampilkan menu utama (landing page)
show_landing_page() {
    echo "============================"
    echo "Library Management System"
    echo "============================"
    echo "1. Admin"
    echo "2. Pengunjung"
    echo "3. Keluar"
    echo "============================"
}

# Fungsi untuk menampilkan menu admin
show_admin_menu() {
    echo "====================================="
    echo "Admin Menu"
    echo "====================================="
    echo "1. Tambah Buku"
    echo "2. Hapus Buku"
    echo "3. Edit Buku"
    echo "4. Tampilkan Semua Buku"
    echo "5. Tampilkan Data Peminjam"
    echo "6. Tampilkan Data Peminjam Terlambat"
    echo "7. Kembali ke Halaman Utama"
    echo "====================================="
}

# Fungsi untuk menampilkan menu pengunjung
show_visitor_menu() {
    echo "============================"
    echo "Pengunjung Menu"
    echo "============================"
    echo "1. Tampilkan Semua Buku"
    echo "2. Cari Buku"
    echo "3. Pinjam Buku"
    echo "4. Kembalikan Buku"
    echo "5. Kembali ke Halaman Utama"
    echo "============================"
}

# Fungsi untuk autentikasi admin
authenticate_admin() {
    local username
    local password

    echo "Masukkan username:"
    read username
    echo "Masukkan password (tidak akan ditampilkan):"
    stty -echo
    read password
    stty echo
    echo

    if [ "$username" = "admin" ] && [ "$password" = "admin123" ]; then
        return 0
    else
        return 1
    fi
}

# Fungsi untuk menambah buku
add_book() {
    echo "Masukkan judul buku:"
    read title
    echo "Masukkan penulis buku:"
    read author
    echo "Masukkan tahun terbit:"
    read year
    echo "$title | $author | $year" >> $BOOKS_FILE
    echo "Buku berhasil ditambahkan."
}

# Fungsi untuk menghapus buku
delete_book() {
    echo "Daftar buku yang tersedia:"
    list_books
    echo "================================================================="
    echo "Pilih nomor buku yang ingin dihapus (atau 0 untuk batal):"
    read book_index

    if [ "$book_index" -eq 0 ]; then
        echo "Penghapusan buku dibatalkan."
    elif [ "$book_index" -gt 0 ]; then
        book_to_delete=$(sed "${book_index}q;d" $BOOKS_FILE)
        if [ -n "$book_to_delete" ]; then
            grep -v -F "$book_to_delete" $BOOKS_FILE > temp.txt && mv temp.txt $BOOKS_FILE
            echo "Buku berhasil dihapus."
        else
            echo "Nomor buku tidak valid."
        fi
    else
        echo "Nomor buku tidak valid."
    fi
}

# Fungsi untuk mengedit buku
edit_book() {
    echo "Daftar buku yang tersedia:"
    list_books
    echo "================================================================="
    echo "Pilih nomor buku yang ingin diedit (atau 0 untuk batal):"
    read book_index

    if [ "$book_index" -eq 0 ]; then
        echo "Pengeditan buku dibatalkan."
    elif [ "$book_index" -gt 0 ]; then
        book_to_edit=$(sed "${book_index}q;d" $BOOKS_FILE)
        if [ -n "$book_to_edit" ]; then
            IFS='|' read -r old_title old_author old_year <<< "$book_to_edit"
            echo "Masukkan judul baru (kosongkan untuk tidak mengubah):"
            read new_title
            echo "Masukkan penulis baru (kosongkan untuk tidak mengubah):"
            read new_author
            echo "Masukkan tahun terbit baru (kosongkan untuk tidak mengubah):"
            read new_year

            # Tetapkan nilai baru jika tidak kosong, jika kosong gunakan nilai lama
            [ -z "$new_title" ] && new_title="$old_title"
            [ -z "$new_author" ] && new_author="$old_author"
            [ -z "$new_year" ] && new_year="$old_year"

            new_book="$new_title | $new_author | $new_year"
            sed -i "${book_index}s/.*/$new_book/" $BOOKS_FILE
            echo "Buku berhasil diedit."
        else
            echo "Nomor buku tidak valid."
        fi
    else
        echo "Nomor buku tidak valid."
    fi
}

# Fungsi untuk mencari buku
search_book() {
    echo "Masukkan judul buku (atau sebagian judul):"
    read title
    grep -i "$title" $BOOKS_FILE
}

# Fungsi untuk menampilkan semua buku dalam format tabel
list_books() {
    if [ -f $BOOKS_FILE ]; then
        echo "========================================================================="
        printf "| %-3s | %-30s | %-20s | %-4s |\n" "No" "Judul Buku" "Penulis" "Tahun"
        echo "========================================================================="
        i=1
        while IFS='|' read -r title author year; do
            printf "| %-3d | %-30s | %-20s | %-4s |\n" "$i" "$title" "$author" "$year"
            i=$((i+1))
        done < $BOOKS_FILE
        echo "========================================================================="
    else
        echo "Tidak ada buku dalam perpustakaan."
    fi
}

# Fungsi untuk menampilkan data peminjam
list_borrowers() {
    if [ -f $BORROW_FILE ]; then
        echo "==================================================================================================="
        printf "| %-30s | %-20s | %-15s | %-15s |\n" "Judul Buku" "Peminjam" "Tanggal Pinjam" "Batas Pengembalian"
        echo "==================================================================================================="
        while IFS='|' read -r title borrower borrow_date return_date; do
            printf "| %-30s | %-20s | %-15s | %-15s |\n" "$title" "$borrower" "$borrow_date" "$return_date"
        done < $BORROW_FILE
        echo "==================================================================================================="
    else
        echo "Tidak ada data peminjam."
    fi
}

# Fungsi untuk menampilkan data peminjam terlambat
list_late_borrowers() {
    if [ -f $BORROW_FILE ]; then
        echo "====================================================================================================================="
        printf "| %-30s | %-20s | %-15s | %-15s | %-10s |\n" "Judul Buku" "Peminjam" "Tanggal Pinjam" "Tanggal kembali" "Denda"
        echo "====================================================================================================================="
        current_date=$(date +"%Y-%m-%d")
        current_timestamp=$(date -d "$current_date" +%s)
        while IFS='|' read -r title borrower borrow_date return_date; do
            return_timestamp=$(date -d "$return_date" +%s)
            if [ $current_timestamp -gt $return_timestamp ]; then
                diff=$(( (current_timestamp - return_timestamp) / 3600 )) # Menghitung selisih waktu dalam jam
                fine=$(( diff * 1000 )) # Denda 1000 per jam keterlambatan
                printf "| %-30s | %-20s | %-15s | %-15s | Rp%-8d |\n" "$title" "$borrower" "$borrow_date" "$return_date" "$fine"
            fi
        done < $BORROW_FILE
        echo "===================================================================================================================="
    else
        echo "Tidak ada data peminjam."
    fi
}

# Fungsi untuk meminjam buku
borrow_book() {
    echo "Daftar buku yang tersedia:"
    list_books
    echo "================================================================="
    # Meminta pengguna untuk memilih nomor urutan buku
    echo "Masukkan nomor buku yang ingin dipinjam (atau 0 untuk batal):"
    read book_number

    # Validasi nomor buku yang dipilih
    if [ "$book_number" = "0" ]; then
        echo "Peminjaman buku dibatalkan."
        return
    elif ! [[ "$book_number" =~ ^[0-9]+$ ]]; then
        echo "Nomor buku tidak valid."
        return
    fi

    # Membaca buku yang dipilih dari file
    selected_book=$(sed -n "${book_number}p" $BOOKS_FILE)

    # Memeriksa apakah buku dipilih ada
    if [ -z "$selected_book" ]; then
        echo "Nomor buku tidak valid."
        return
    fi

    # Memisahkan judul buku dari data yang dipilih
    title=$(echo "$selected_book" | awk -F "|" '{print $1}')

    # Meminta nama peminjam
    echo "Masukkan nama peminjam:"
    read borrower
    borrow_date=$(date +"%Y-%m-%d")
    return_date=$(date -d "$borrow_date +3 days" +"%Y-%m-%d") # batas pengembalian 3 hari
    echo "$title | $borrower | $borrow_date | $return_date" >> $BORROW_FILE
    echo "Buku berhasil dipinjam. Invoice:"
    echo "==============================="
    echo "Judul Buku     : $title"
    echo "Nama Peminjam  : $borrower"
    echo "Tanggal Pinjam : $borrow_date"
    echo "Batas Kembali  : $return_date"
    echo "==============================="
}

# Fungsi untuk mengembalikan buku
return_book() {
    echo "Masukkan judul buku yang ingin dikembalikan:"
    read title
    echo "Masukkan nama peminjam:"
    read borrower
    current_date=$(date +"%Y-%m-%d")
    # Validasi input untuk memastikan bahwa title dan borrower tidak kosong
    if [ -z "$title" ] || [ -z "$borrower" ]; then
        echo "Judul buku dan nama peminjam harus diisi."
        return
    fi

    record=$(grep "$title | $borrower" $BORROW_FILE)
    if [ -z "${record}" ]; then
        echo "Data peminjaman tidak ditemukan."
    else
        return_date=$(echo $record | awk -F'|' '{print $4}')
        return_timestamp=$(date -d "$return_date" +%s)
        current_timestamp=$(date -d "$current_date" +%s)
        if [ $current_timestamp -gt $return_timestamp ]; then
            diff=$(( (current_timestamp - return_timestamp) / 3600 )) # Menghitung selisih waktu dalam jam
            fine=$(( diff * 1000 )) # Denda 1000 per jam keterlambatan
            echo "Anda terlambat mengembalikan buku selama $diff jam. Denda: Rp$fine"
        else
            echo "Buku berhasil dikembalikan tepat waktu."
        fi
        echo "$title | $borrower | $current_date" >> $RETURN_FILE
        grep -v "$record" $BORROW_FILE > temp.txt && mv temp.txt $BORROW_FILE
    fi
}


# Main loop
while true; do
    show_landing_page
    echo "Pilih opsi (1-3):"
    read main_option
    case $main_option in
        1)
            if authenticate_admin; then
                while true; do
                    show_admin_menu
                    echo "Pilih opsi (1-7):"
                    read admin_option
                    case $admin_option in
                        1) add_book ;;
                        2) delete_book ;;
                        3) edit_book ;;
                        4) list_books ;;
                        5) list_borrowers ;;
                        6) list_late_borrowers ;;
                        7) break ;;
                        *) echo "Opsi tidak valid." ;;
                    esac
                done
            else
                echo "Autentikasi gagal. Kembali ke halaman utama."
            fi
            ;;
        2)
            while true; do
                show_visitor_menu
                echo "Pilih opsi (1-5):"
                read visitor_option
                case $visitor_option in
                    1) list_books ;;
                    2) search_book ;;
                    3) borrow_book ;;
                    4) return_book ;;
                    5) break ;;
                    *) echo "Opsi tidak valid." ;;
                esac
            done
            ;;
        3)
            echo "Terima kasih telah menggunakan sistem manajemen perpustakaan."
            exit 0
            ;;
        *)
            echo "Opsi tidak valid."
            ;;
    esac
done
