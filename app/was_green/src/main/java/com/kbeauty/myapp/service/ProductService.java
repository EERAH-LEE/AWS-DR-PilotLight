package com.kbeauty.myapp.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.kbeauty.myapp.entity.DTO;
import com.kbeauty.myapp.entity.Product;
import com.kbeauty.myapp.repository.ProductDetailRepository;
import com.kbeauty.myapp.repository.ProductRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProductService {
	@Autowired
    private ProductRepository productRepository;
	
	@Autowired
	private ProductDetailRepository detailRepository;

    public List<Product> getAllProducts() {
        return productRepository.findAllByOrderByProductIdDesc();
    }
    
    
    public DTO getProductDetail(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("상품을 찾을 수 없습니다."));
        
        List<String> images = detailRepository.findAllByProductIdOrderBySortOrderAsc(id)
        							.stream()
        							.map(d -> d.getImageUrl())
        							.collect(java.util.stream.Collectors.toList());
                
        return new DTO(product, images);
    }
}