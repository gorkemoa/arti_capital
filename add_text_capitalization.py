#!/usr/bin/env python3
"""
TextField ve TextFormField'lara otomatik olarak textCapitalization ekler.
Email, password, TC, uppercase gibi özel durumlar hariç.
"""

import os
import re
from pathlib import Path

def should_skip_field(content_before, content_after):
    """Bu field'ı atlamalı mıyız? (Email, password, vs.)"""
    combined = content_before + content_after
    
    # Email, password, TC, uppercase kontrolü
    skip_patterns = [
        r'email',
        r'e-posta',
        r'eposta',
        r'password',
        r'şifre',
        r'sifre',
        r'parola',
        r'tc\s*kimlik',
        r'tc\s*no',
        r'vergi\s*no',
        r'mersis',
        r'iban',
        r'uppercase',
        r'keyboardType:\s*TextInputType\.number',
        r'keyboardType:\s*TextInputType\.phone',
        r'FilteringTextInputFormatter\.digitsOnly',
        r'obscureText:\s*true',
    ]
    
    for pattern in skip_patterns:
        if re.search(pattern, combined, re.IGNORECASE):
            return True
    
    return False

def has_text_capitalization(field_content):
    """Bu field zaten textCapitalization içeriyor mu?"""
    return 'textCapitalization:' in field_content

def add_capitalization_to_field(match, file_content):
    """Bir TextField/TextFormField'a textCapitalization ekle"""
    start = match.start()
    end = match.end()
    
    # Field içeriğini al
    field_start = start
    paren_count = 1
    i = end
    
    while i < len(file_content) and paren_count > 0:
        if file_content[i] == '(':
            paren_count += 1
        elif file_content[i] == ')':
            paren_count -= 1
        i += 1
    
    field_end = i
    field_content = file_content[field_start:field_end]
    
    # Zaten textCapitalization varsa atla
    if has_text_capitalization(field_content):
        return None
    
    # Önceki ve sonraki içeriği kontrol et (context için)
    context_before = file_content[max(0, start - 500):start]
    context_after = file_content[end:min(len(file_content), end + 500)]
    
    # Özel durumları atla
    if should_skip_field(context_before, context_after):
        return None
    
    # TextField( veya TextFormField( sonrasına git
    insert_pos = end
    
    # İlk property'yi bul
    # Eğer hemen sonra bir property varsa, ondan önce ekle
    # Değilse, ( sonrasına ekle
    remaining = file_content[end:field_end]
    
    # Boşlukları atla
    i = 0
    while i < len(remaining) and remaining[i] in ' \n\t':
        i += 1
    
    # textCapitalization'ı ekle
    if i < len(remaining) and remaining[i] != ')':
        # Property'ler var, başa ekle
        insertion = '\n            textCapitalization: TextCapitalization.sentences,'
    else:
        # Boş field, ekle
        insertion = '\n            textCapitalization: TextCapitalization.sentences,\n          '
    
    return (insert_pos, insertion)

def process_file(file_path):
    """Bir dosyayı işle"""
    print(f"İşleniyor: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # TextField( ve TextFormField( bul
    patterns = [
        r'TextField\(',
        r'TextFormField\(',
    ]
    
    modifications = []
    
    for pattern in patterns:
        for match in re.finditer(pattern, content):
            result = add_capitalization_to_field(match, content)
            if result:
                modifications.append(result)
    
    # Değişiklikleri uygula (tersten sıralayarak)
    if modifications:
        modifications.sort(reverse=True, key=lambda x: x[0])
        
        for pos, insertion in modifications:
            content = content[:pos] + insertion + content[pos:]
        
        # Dosyayı kaydet
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"  ✅ {len(modifications)} değişiklik yapıldı")
        return len(modifications)
    else:
        print(f"  ℹ️  Değişiklik gerekmedi")
        return 0

def main():
    """Ana fonksiyon"""
    project_root = Path(__file__).parent
    views_dir = project_root / 'lib' / 'views'
    
    if not views_dir.exists():
        print(f"❌ Views klasörü bulunamadı: {views_dir}")
        return
    
    print(f"📁 Views klasörü taranıyor: {views_dir}\n")
    
    total_files = 0
    total_changes = 0
    
    # Tüm .dart dosyalarını işle
    for dart_file in views_dir.glob('**/*.dart'):
        total_files += 1
        changes = process_file(dart_file)
        total_changes += changes
    
    print(f"\n✅ Tamamlandı!")
    print(f"📊 {total_files} dosya işlendi")
    print(f"🔧 {total_changes} TextField'a textCapitalization eklendi")

if __name__ == '__main__':
    main()
