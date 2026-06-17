package com.kbeauty.myapp.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "products")
@Getter @Setter
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long productId;

    private String brandName;
    private String productName;
    private String subTitle;
    private BigDecimal originalPrice;
    private Integer discountRate;
    private String mainImageUrl;
    private Boolean isGlobalBest;

    @Column(insertable = false, updatable = false)
    private LocalDateTime createdAt;

    // 현재 할인가 계산 로직 (비즈니스 메서드)
    public BigDecimal getCurrentPrice() {
        if (discountRate == null || discountRate == 0) return originalPrice;
        return originalPrice.multiply(BigDecimal.valueOf(1 - (discountRate / 100.0)));
    }
}