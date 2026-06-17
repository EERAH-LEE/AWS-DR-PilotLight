-- K-Beauty shop initial product data for MySQL/Azure Database for MySQL.
-- Run after the application has created/updated the JPA tables.
-- Members and inquiries are user-generated data, so only products are seeded here.

START TRANSACTION;

INSERT INTO products (
    product_id,
    brand_name,
    product_name,
    sub_title,
    original_price,
    discount_rate,
    main_image_url,
    is_global_best,
    created_at
) VALUES
    (1, 'd''Alba', '화이트 트러플 퍼스트 스프레이 세럼 100ml', '광채 보습을 위한 미스트 세럼', 35000, 24, 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (2, 'Anua', '어성초 77 수딩 토너 250ml', '민감 피부를 위한 진정 토너', 28000, 18, 'https://images.unsplash.com/photo-1612817288484-6f916006741a?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (3, 'Beauty of Joseon', '맑은쌀 선크림 SPF50+ PA++++', '매일 바르기 좋은 촉촉한 선케어', 22000, 10, 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (4, 'Torriden', '다이브인 저분자 히알루론산 세럼 50ml', '수분 레이어링을 위한 저자극 세럼', 26000, 15, 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (5, 'Round Lab', '1025 독도 토너 200ml', '산뜻하게 닦아내는 데일리 토너', 24000, 12, 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (6, 'Laneige', '워터뱅크 블루 히알루로닉 크림', '건조한 피부를 채우는 수분 크림', 42000, 20, 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (7, 'Dr.G', '레드 블레미쉬 클리어 수딩 크림', '민감 피부를 위한 산뜻한 진정 크림', 36000, 22, 'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (8, 'Innisfree', '그린티 씨드 히알루론 세럼', '녹차 수분 에너지 세럼', 33000, 16, 'https://images.unsplash.com/photo-1617897903246-719242758050?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (9, 'COSRX', '원스텝 오리지널 클리어 패드', '매끈한 피부결을 위한 토너 패드', 19000, 8, 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?auto=format&fit=crop&q=85&w=900', 0, NOW()),
    (10, 'Mediheal', '티트리 에센셜 마스크 10매', '편안한 진정을 위한 데일리 마스크', 18000, 25, 'https://images.unsplash.com/photo-1573461160327-b450ce3d8e7f?auto=format&fit=crop&q=85&w=900', 0, NOW()),
    (11, 'Sulwhasoo', '윤조에센스 6세대 60ml', '첫 단계 피부 균형 에센스', 105000, 10, 'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (12, 'Etude', '순정 약산성 5.5 폼 클렌저', '편안한 약산성 데일리 클렌저', 13000, 14, 'https://images.unsplash.com/photo-1580870069867-74c57ee1bb07?auto=format&fit=crop&q=85&w=900', 0, NOW()),
    (13, 'HERA', '블랙 쿠션 SPF34 PA++', '얇고 밀착되는 세미매트 쿠션', 72000, 18, 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&q=85&w=900', 1, NOW()),
    (14, 'Rom&nd', '쥬시 래스팅 틴트 베스트 컬러', '맑고 생기 있는 데일리 립 틴트', 13000, 7, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?auto=format&fit=crop&q=85&w=900', 0, NOW()),
    (15, 'Peripera', '잉크 무드 글로이 틴트', '촉촉한 광택의 무드 립 컬러', 12000, 10, 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?auto=format&fit=crop&q=85&w=900', 0, NOW()),
    (16, 'Abib', '어성초 스팟 패드 카밍 터치', '간편하게 붙이는 진정 케어 패드', 24000, 19, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?auto=format&fit=crop&q=85&w=900', 0, NOW())
ON DUPLICATE KEY UPDATE
    brand_name = VALUES(brand_name),
    product_name = VALUES(product_name),
    sub_title = VALUES(sub_title),
    original_price = VALUES(original_price),
    discount_rate = VALUES(discount_rate),
    main_image_url = VALUES(main_image_url),
    is_global_best = VALUES(is_global_best);

INSERT INTO product_details (
    detail_id,
    product_id,
    image_url,
    sort_order
) VALUES
    (1, 1, 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&q=85&w=900', 1),
    (2, 2, 'https://images.unsplash.com/photo-1612817288484-6f916006741a?auto=format&fit=crop&q=85&w=900', 1),
    (3, 3, 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&q=85&w=900', 1),
    (4, 4, 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&q=85&w=900', 1),
    (5, 5, 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?auto=format&fit=crop&q=85&w=900', 1),
    (6, 6, 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?auto=format&fit=crop&q=85&w=900', 1),
    (7, 7, 'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?auto=format&fit=crop&q=85&w=900', 1),
    (8, 8, 'https://images.unsplash.com/photo-1617897903246-719242758050?auto=format&fit=crop&q=85&w=900', 1),
    (9, 9, 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?auto=format&fit=crop&q=85&w=900', 1),
    (10, 10, 'https://images.unsplash.com/photo-1573461160327-b450ce3d8e7f?auto=format&fit=crop&q=85&w=900', 1),
    (11, 11, 'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?auto=format&fit=crop&q=85&w=900', 1),
    (12, 12, 'https://images.unsplash.com/photo-1580870069867-74c57ee1bb07?auto=format&fit=crop&q=85&w=900', 1),
    (13, 13, 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&q=85&w=900', 1),
    (14, 14, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?auto=format&fit=crop&q=85&w=900', 1),
    (15, 15, 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?auto=format&fit=crop&q=85&w=900', 1),
    (16, 16, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?auto=format&fit=crop&q=85&w=900', 1)
ON DUPLICATE KEY UPDATE
    product_id = VALUES(product_id),
    image_url = VALUES(image_url),
    sort_order = VALUES(sort_order);

COMMIT;
