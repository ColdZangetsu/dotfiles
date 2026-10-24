function que-disco --description 'Muestra desde qué disco arrancó el sistema'
    # Usa UUIDs: los nombres nvme0/nvme1 pueden intercambiarse entre arranques
    set -l uuid (findmnt -no UUID /)
    set -l src (findmnt -no SOURCE /)
    echo "Raíz: $src  (UUID $uuid)"
    switch $uuid
        case 41735f63-686e-45d9-ba4c-009b155a162a
            echo "✅ Estás en el 2 TB"
        case d38bafdb-2d1d-4068-b290-72ff1f8c6ea2
            echo "⚠️  Sigues en el 512"
        case '*'
            echo "❓ Disco desconocido"
    end
end
