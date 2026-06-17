package com.kbeauty.myapp.entity;


import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "product_details")
@Getter @Setter
@NoArgsConstructor
public class ProductDetail {
	
	@Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long detailId;
    private Long productId;
    private String imageUrl;
    private Integer sortOrder;

}
