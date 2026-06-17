package com.kbeauty.myapp.entity;

import java.util.List;

import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@NoArgsConstructor
@Getter
@Setter
public class DTO {
	
	private Product product;
	private List<String> imges;

	public DTO(Product product, List<String> images) {
		this.product = product;
		this.imges = images;
	}



}
