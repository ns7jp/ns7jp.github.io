(function () {
    'use strict';

    var targetSelector = [
        '.network-figure .mermaid',
        '.network-figure img',
        '.work-image-container > img'
    ].join(', ');

    function initLightbox() {
        var targets = Array.prototype.slice.call(document.querySelectorAll(targetSelector));

        if (!targets.length) {
            return;
        }

        var overlay = document.createElement('div');
        var closeButton = document.createElement('button');
        var activeContent = null;
        var returnFocus = null;
        var previousOverflow = '';

        overlay.className = 'lightbox-overlay';
        overlay.setAttribute('role', 'dialog');
        overlay.setAttribute('aria-modal', 'true');
        overlay.setAttribute('aria-label', 'Enlarged view');
        overlay.setAttribute('aria-hidden', 'true');

        closeButton.type = 'button';
        closeButton.className = 'lightbox-close';
        closeButton.setAttribute('aria-label', 'Close enlarged view');
        closeButton.innerHTML = '&times;';

        overlay.appendChild(closeButton);
        document.body.appendChild(overlay);

        function targetLabel(target) {
            var figure = target.closest('figure');
            var caption = figure && figure.querySelector('figcaption');

            return target.getAttribute('alt') ||
                (caption && caption.textContent.trim()) ||
                'Image';
        }

        function createContent(target) {
            if (target.tagName === 'IMG') {
                var image = document.createElement('img');

                image.className = 'lightbox-content';
                image.src = target.currentSrc || target.src;
                image.alt = target.getAttribute('alt') || '';
                image.decoding = 'async';

                return image;
            }

            var diagram = target.cloneNode(true);

            diagram.classList.remove('lightbox-trigger');
            diagram.classList.add('lightbox-content', 'lightbox-diagram');
            diagram.removeAttribute('tabindex');
            diagram.removeAttribute('role');
            diagram.removeAttribute('aria-label');

            return diagram;
        }

        function openLightbox(target) {
            if (activeContent) {
                activeContent.remove();
            }

            activeContent = createContent(target);
            overlay.appendChild(activeContent);
            returnFocus = document.activeElement === document.body ? target : document.activeElement;
            previousOverflow = document.body.style.overflow;
            document.body.style.overflow = 'hidden';
            overlay.classList.add('active');
            overlay.setAttribute('aria-hidden', 'false');
            closeButton.focus();
        }

        function closeLightbox() {
            if (!overlay.classList.contains('active')) {
                return;
            }

            overlay.classList.remove('active');
            overlay.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = previousOverflow;

            if (activeContent) {
                activeContent.remove();
                activeContent = null;
            }

            if (returnFocus && typeof returnFocus.focus === 'function') {
                returnFocus.focus();
            }
        }

        function addTrigger(target) {
            target.classList.add('lightbox-trigger');
            target.setAttribute('tabindex', '0');
            target.setAttribute('role', 'button');
            target.setAttribute('aria-label', 'Open enlarged view: ' + targetLabel(target));

            target.addEventListener('click', function () {
                openLightbox(target);
            });

            target.addEventListener('keydown', function (event) {
                if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    openLightbox(target);
                }
            });

            if (target.tagName === 'IMG' && target.closest('.work-image-container')) {
                var container = target.closest('.work-image-container');

                container.classList.add('lightbox-trigger');
                container.addEventListener('click', function (event) {
                    if (event.target === target || event.target.closest('a, button')) {
                        return;
                    }

                    openLightbox(target);
                });
            }
        }

        targets.forEach(addTrigger);

        closeButton.addEventListener('click', closeLightbox);

        overlay.addEventListener('click', function (event) {
            if (event.target === overlay) {
                closeLightbox();
            }
        });

        document.addEventListener('keydown', function (event) {
            if (!overlay.classList.contains('active')) {
                return;
            }

            if (event.key === 'Escape') {
                closeLightbox();
            } else if (event.key === 'Tab') {
                event.preventDefault();
                closeButton.focus();
            }
        });
    }

    document.addEventListener('DOMContentLoaded', initLightbox);
}());
