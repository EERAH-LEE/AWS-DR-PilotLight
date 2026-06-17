package com.kbeauty.myapp.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.kbeauty.myapp.entity.Product;

public interface ProductRepository extends JpaRepository<Product, Long> {

    // 전체 상품 리스트 조회
    List<Product> findAllByOrderByProductIdDesc();
}