package com.kbeauty.myapp.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BlueController {

    @GetMapping(value = {"/blue", "/api/blue"}, produces = "text/plain;charset=UTF-8")
    public String blue() {
        return " 2026-06-26 금요일 : CICD 성공" ;
    
    }
}
