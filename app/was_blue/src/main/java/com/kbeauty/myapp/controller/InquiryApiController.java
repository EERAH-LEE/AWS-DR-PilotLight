package com.kbeauty.myapp.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.kbeauty.myapp.entity.Inquiry;
import com.kbeauty.myapp.repository.InquiryRepository;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/inquiries")
@RequiredArgsConstructor
public class InquiryApiController {

    private final InquiryRepository inquiryRepository;

    @GetMapping
    public List<Inquiry> getInquiries() {
        return inquiryRepository.findAllByOrderByInquiryIdDesc();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Inquiry createInquiry(@RequestBody InquiryRequest request) {
        if (isBlank(request.title()) || isBlank(request.writer()) || isBlank(request.content())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "문의 제목, 작성자, 내용을 모두 입력해주세요.");
        }

        Inquiry inquiry = new Inquiry();
        inquiry.setCategory(isBlank(request.category()) ? "기타 문의" : request.category());
        inquiry.setTitle(request.title());
        inquiry.setWriter(request.writer());
        inquiry.setContent(request.content());
        return inquiryRepository.save(inquiry);
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    public record InquiryRequest(String category, String title, String writer, String content) {
    }
}
