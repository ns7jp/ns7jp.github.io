/*
 * main.js — サイト共通のインタラクション処理（vanilla JS、外部ライブラリ非依存）
 *
 * これまで各ページに個別コピペされていた jQuery 製のローダー/メニュー/スクロール演出を
 * 1ファイルに集約し、jQuery（外部CDN）への依存も廃止した。
 * CDN がブロックされる環境でもローダーが画面を覆ったまま固まらないよう、
 * ローダー解除は window の load イベントに加えて、一定時間後の強制解除も行う。
 */
(function () {
    'use strict';

    /* ===== ローダーの非表示処理 ===== */
    function hideLoader() {
        var loader = document.querySelector('.loader');
        if (!loader || loader.classList.contains('is-hidden')) return;
        loader.classList.add('is-hidden');
        loader.style.transition = 'opacity 0.8s ease';
        loader.style.opacity = '0';
        window.setTimeout(function () {
            loader.style.display = 'none';
        }, 800);
    }
    window.addEventListener('load', hideLoader);
    // 外部フォント/アイコン等の読み込みが遅延・失敗しても、画面がスピナーのまま
    // 固まり続けないようにする安全策（load イベントに依存しない強制解除）。
    window.setTimeout(hideLoader, 4000);

    /* ===== ハンバーガーメニューの開閉処理（キーボード・スクリーンリーダー対応） ===== */
    var menuButton = document.querySelector('.res-menu');
    var siteNav = document.querySelector('header nav');
    if (menuButton && siteNav) {
        menuButton.addEventListener('click', function () {
            var isOpen = siteNav.classList.toggle('show');
            menuButton.classList.toggle('show2', isOpen);
            menuButton.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
        });
    }

    /* ===== スクロール連動演出（ヘッダー縮小 / スキルバー / セクションフェードイン） ===== */
    var header = document.querySelector('header');
    var skillProgressBars = document.querySelectorAll('.skill-progress[data-progress]');
    var fadeInSections = document.querySelectorAll(
        '.hiring-summary, .support-scope, .quick-intro, .skills-preview, .works-preview, ' +
        '.contact-cta, .support-toolkit, .skill-detail-card, .work-showcase-item'
    );

    function handleScroll() {
        var scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        var viewportBottom = scrollTop + window.innerHeight;

        if (header) {
            header.classList.toggle('scrolled', scrollTop > 100);
        }

        skillProgressBars.forEach(function (bar) {
            var top = bar.getBoundingClientRect().top + scrollTop;
            if (viewportBottom > top) {
                bar.style.width = bar.getAttribute('data-progress') + '%';
            }
        });

        fadeInSections.forEach(function (section) {
            var top = section.getBoundingClientRect().top + scrollTop;
            if (viewportBottom > top + 50) {
                section.classList.add('visible');
            }
        });
    }
    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll();

    /* ===== ページ内アンカーリンクのスムーススクロール ===== */
    document.querySelectorAll('a[href^="#"]').forEach(function (link) {
        var href = link.getAttribute('href');
        if (!href || href.length < 2) return;
        link.addEventListener('click', function (e) {
            var target;
            try {
                target = document.querySelector(href);
            } catch (err) {
                return;
            }
            if (!target) return;
            e.preventDefault();
            var top = target.getBoundingClientRect().top +
                (window.pageYOffset || document.documentElement.scrollTop) - 80;
            window.scrollTo({ top: top, behavior: 'smooth' });
        });
    });

    /* ===== works.html：作品フィルター ===== */
    var filterButtons = document.querySelectorAll('.filter-btn');
    if (filterButtons.length) {
        var showcaseItems = document.querySelectorAll('.work-showcase-item');
        filterButtons.forEach(function (button) {
            button.addEventListener('click', function () {
                filterButtons.forEach(function (b) { b.classList.remove('active'); });
                button.classList.add('active');
                var filter = button.getAttribute('data-filter');
                showcaseItems.forEach(function (item) {
                    var categories = (item.getAttribute('data-category') || '').split(/\s+/);
                    var show = filter === 'all' || categories.indexOf(filter) !== -1;
                    item.style.display = show ? '' : 'none';
                });
            });
        });
    }

    /* ===== contact.html：入力欄フォーカス時のラベル演出 ===== */
    document.querySelectorAll('.input-wrapper input, .textarea-wrapper textarea').forEach(function (field) {
        field.addEventListener('focus', function () {
            field.parentElement.classList.add('focused');
        });
        field.addEventListener('blur', function () {
            if (field.value === '') {
                field.parentElement.classList.remove('focused');
            }
        });
    });

    /* ===== index.html：ヒーロー背景のクロスフェード（旧 jquery.bgswitcher.js の置き換え） ===== */
    var heroSlider = document.querySelector('.hero-slider');
    if (heroSlider) {
        var heroImages = ['image/works.jpg', 'image/me.jpg', 'image/contact.jpg', 'image/skills.jpg'];
        for (var i = heroImages.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1));
            var tmp = heroImages[i];
            heroImages[i] = heroImages[j];
            heroImages[j] = tmp;
        }

        var layerA = document.createElement('div');
        var layerB = document.createElement('div');
        [layerA, layerB].forEach(function (layer) {
            layer.className = 'hero-slider-layer';
            heroSlider.appendChild(layer);
        });
        layerA.style.backgroundImage = 'url(' + heroImages[0] + ')';
        layerA.classList.add('is-visible');

        var current = layerA;
        var next = layerB;
        var index = 0;
        window.setInterval(function () {
            index = (index + 1) % heroImages.length;
            next.style.backgroundImage = 'url(' + heroImages[index] + ')';
            next.classList.add('is-visible');
            current.classList.remove('is-visible');
            var swap = current;
            current = next;
            next = swap;
        }, 5000);
    }
})();
