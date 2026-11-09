<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        // Handler terpadu untuk 404 pada API
        $exceptions->render(function (NotFoundHttpException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '404',
                    'message' => 'Sumber daya tidak ditemukan.',
                    'errors' => null,
                ], 404);
            }
        });

        // Handler terpadu untuk 422 Validasi pada API
        $exceptions->render(function (ValidationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'status' => 'gagal',
                    'code' => '422',
                    'message' => $e->getMessage() ?: 'Validasi formulir gagal.',
                    'errors' => $e->errors(),
                ], 422);
            }
        });

        // Handler umum untuk 500 Galat Server pada API
        $exceptions->render(function (Throwable $e, Request $request) {
            if ($request->is('api/*')) {
                $status = $e instanceof HttpExceptionInterface ? $e->getStatusCode() : 500;

                return response()->json([
                    'status' => 'gagal',
                    'code' => (string) $status,
                    'message' => 'Terjadi kesalahan pada server.',
                    'errors' => null,
                ], $status);
            }
        });
    })->create();
