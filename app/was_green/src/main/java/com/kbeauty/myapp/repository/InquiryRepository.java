package com.kbeauty.myapp.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.kbeauty.myapp.entity.Inquiry;

public interface InquiryRepository extends JpaRepository<Inquiry, Long> {
    List<Inquiry> findAllByOrderByInquiryIdDesc();
}
