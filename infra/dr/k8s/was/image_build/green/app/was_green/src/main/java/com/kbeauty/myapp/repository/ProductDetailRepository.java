package com.kbeauty.myapp.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.kbeauty.myapp.entity.ProductDetail;

public interface ProductDetailRepository extends JpaRepository<ProductDetail, Long> {
    List<ProductDetail> findAllByProductIdOrderBySortOrderAsc(Long productId);
}