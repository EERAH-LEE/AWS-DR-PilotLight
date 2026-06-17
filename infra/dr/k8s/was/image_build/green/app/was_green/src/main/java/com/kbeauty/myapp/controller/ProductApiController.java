package com.kbeauty.myapp.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.kbeauty.myapp.entity.DTO;
import com.kbeauty.myapp.entity.Product;
import com.kbeauty.myapp.service.ProductService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductApiController {
    private final ProductService productService;

    @GetMapping("/all")
    public List<Product> getAllList() {
        // [REQ-04] Read-Replica 환경에서 이 API가 호출되도록 구성하면 성능이 최적화됩니다.
        return productService.getAllProducts();
    }

    // 상세페이지용 API
    @GetMapping("/{id}")
    public DTO getProductDetail(@PathVariable Long id) {
        return productService.getProductDetail(id);
    }
}
