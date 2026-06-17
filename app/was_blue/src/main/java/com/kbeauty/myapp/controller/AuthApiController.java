package com.kbeauty.myapp.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.kbeauty.myapp.entity.Member;
import com.kbeauty.myapp.repository.MemberRepository;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthApiController {

    private final MemberRepository memberRepository;

    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest request, HttpSession session) {
        if (isBlank(request.email()) || isBlank(request.password())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "이메일과 비밀번호를 입력해주세요.");
        }

        Member member = memberRepository.findByEmail(request.email())
                .orElseGet(() -> memberRepository.save(new Member(
                        request.email(),
                        getDefaultName(request.email()),
                        request.password())));

        if (!member.getPassword().equals(request.password())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "비밀번호가 일치하지 않습니다.");
        }

        String token = "member-" + member.getMemberId();
        saveSession(session, member.getMemberId(), member.getEmail(), member.getName(), token);
        return toResponse(member.getMemberId(), member.getEmail(), member.getName(), token, session);
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public LoginResponse register(@RequestBody RegisterRequest request, HttpSession session) {
        if (isBlank(request.email()) || isBlank(request.password()) || isBlank(request.name())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "회원 정보를 모두 입력해주세요.");
        }

        if (memberRepository.findByEmail(request.email()).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "이미 가입된 이메일입니다.");
        }

        Member member = memberRepository.save(new Member(request.email(), request.name(), request.password()));
        String token = "member-" + member.getMemberId();
        saveSession(session, member.getMemberId(), member.getEmail(), member.getName(), token);
        return toResponse(member.getMemberId(), member.getEmail(), member.getName(), token, session);
    }

    @GetMapping("/me")
    public ResponseEntity<LoginResponse> me(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(toMissingResponse(request.getRequestedSessionId()));
        }

        Long memberId = (Long) session.getAttribute("memberId");
        String email = (String) session.getAttribute("email");
        String name = (String) session.getAttribute("name");
        String token = (String) session.getAttribute("token");

        if (memberId == null || email == null || name == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(toMissingResponse(session.getId()));
        }

        return ResponseEntity.ok(toResponse(memberId, email, name, token, session));
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return;
        }

        session.invalidate();
    }

    private void saveSession(HttpSession session, Long memberId, String email, String name, String token) {
        session.setAttribute("memberId", memberId);
        session.setAttribute("email", email);
        session.setAttribute("name", name);
        session.setAttribute("token", token);
    }

    private LoginResponse toResponse(Long memberId, String email, String name, String token, HttpSession session) {
        return new LoginResponse(
                memberId,
                email,
                name,
                token,
                session.getId(),
                session.getAttribute("memberId") != null,
                session.getAttribute("email") != null,
                session.getAttribute("name") != null);
    }

    private LoginResponse toMissingResponse(String sessionId) {
        return new LoginResponse(
                null,
                null,
                null,
                null,
                valueOrDefault(sessionId, "none"),
                false,
                false,
                false);
    }

    private String getDefaultName(String email) {
        int atIndex = email.indexOf("@");
        return atIndex > 0 ? email.substring(0, atIndex) : "K-Glow Member";
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private String valueOrDefault(String value, String defaultValue) {
        return value == null || value.isBlank() ? defaultValue : value;
    }

    public record LoginRequest(String email, String password) {
    }

    public record RegisterRequest(String email, String name, String password) {
    }

    public record LoginResponse(
            Long memberId,
            String email,
            String name,
            String token,
            String sessionId,
            boolean hasMemberId,
            boolean hasEmail,
            boolean hasName) {
    }
}
